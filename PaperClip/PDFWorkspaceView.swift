import SwiftUI
import SwiftData
import PencilKit
import UniformTypeIdentifiers

struct ShareImageRequest: Identifiable, Transferable, Sendable {
    let id = UUID()
    let data: Data

    var image: UIImage? { UIImage(data: data) }

    /// 供 ProxyRepresentation 导出的 SwiftUI Image。
    var shareImage: Image { Image(uiImage: image ?? UIImage()) }

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.shareImage)
    }
}

struct PDFWorkspaceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var handwritingLayers: [HandwritingLayer]

    let document: PDFDocumentItem

    @State private var drawings: [Int: Data] = [:]
    @State private var handwritingByPage: [Int: HandwritingLayer] = [:]
    @State private var isWritingEnabled = false
    @State private var isDrawingVisible = true
    @State private var isScratchPresented = false
    @State private var isSelectionMode = false
    @State private var selectionRect: CGRect?
    @State private var pendingSelectionAction: PDFSelectionAction?
    @State private var selectionActionToken = 0
    @State private var cancelSelectionToken = 0
    @State private var undoToken = 0
    @State private var redoToken = 0
    @State private var clearAnswersToken = 0
    @State private var currentSessionIndex = 1
    /// 当前文档存在的所有会话索引（已排序），删除后可不连续。
    @State private var sessionIndices: [Int] = [1]
    @State private var reloadDrawingsToken = 0
    @State private var isSessionManagerPresented = false
    @State private var currentCard: MistakeCard?
    @State private var aiAnalysisRequest: AIAnalysisRequest?
    @State private var shareImageRequest: ShareImageRequest?
    @State private var isPDFPageExportPresented = false
    @State private var canvasSizes: [Int: CGSize] = [:]
    @State private var alert: AppAlert?
    @State private var isClearAnswersConfirmationPresented = false
    @State private var pendingSaveTask: Task<Void, Never>?

    init(document: PDFDocumentItem) {
        self.document = document
        let documentID = document.id
        _handwritingLayers = Query(
            filter: #Predicate<HandwritingLayer> { $0.documentId == documentID }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .secondarySystemBackground).ignoresSafeArea()

                PDFKitCanvasView(
                    url: document.localFileURL,
                    drawings: drawings,
                    isWritingEnabled: isWritingEnabled,
                    isDrawingVisible: isDrawingVisible,
                    isSelectionMode: isSelectionMode,
                    selectionAction: pendingSelectionAction,
                    selectionActionToken: selectionActionToken,
                    cancelSelectionToken: cancelSelectionToken,
                    undoToken: undoToken,
                    redoToken: redoToken,
                    clearAnswersToken: clearAnswersToken,
                    reloadDrawingsToken: reloadDrawingsToken,
                    onDrawingChanged: saveDrawing,
                    onSelectionRectChanged: selectionRectDidChange,
                    onCrop: handleSelectionAction,
                    onError: { message in
                        alert = AppAlert(title: "无法打开 PDF", message: message)
                    },
                    onCanvasSizesChanged: { sizes in
                        canvasSizes = sizes
                    }
                )

                if let rect = selectionRect {
                    SelectionMenuBar(
                        onSave: { performSelectionAction(.saveMistake) },
                        onAnalyze: { performSelectionAction(.analyze) },
                        onShare: { performSelectionAction(.share) },
                        onReselect: resetSelection
                    )
                    .position(x: rect.midX, y: rect.maxY + 44)
                    .transition(.scale(scale: 0.85, anchor: .top).combined(with: .opacity))
                    .zIndex(1)
                }

                if isSelectionMode {
                    VStack {
                        Text(
                            selectionRect != nil
                                ? "拖动选框可移动范围，拖动圆点可调整边界"
                                : "在题目区域拖出矩形，松手后可继续调整范围"
                        )
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.regularMaterial, in: Capsule())
                            .padding(.top, 12)
                        Spacer()
                    }
                }

                if isScratchPresented {
                    FloatingScratchBoard {
                        isScratchPresented = false
                    }
                    .zIndex(2)
                }

            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("完成") { dismiss() }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isPDFPageExportPresented = true
                    } label: {
                        Image(systemName: "paperplane")
                    }
                    .accessibilityLabel("导出页面为长图")

                    Button {
                        leaveSelectionMode()
                        isDrawingVisible = true
                        isWritingEnabled.toggle()
                    } label: {
                        Image(
                            systemName: isWritingEnabled
                                ? "pencil.tip.crop.circle.badge.minus"
                                : "pencil.tip.crop.circle"
                        )
                    }
                    .tint(isWritingEnabled ? .accentColor : .primary)
                    .accessibilityLabel(isWritingEnabled ? "停止书写" : "开始书写")

                    Button {
                        undoToken += 1
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }

                    Button {
                        redoToken += 1
                    } label: {
                        Image(systemName: "arrow.uturn.forward")
                    }

                    Button {
                        isDrawingVisible.toggle()
                    } label: {
                        Image(systemName: isDrawingVisible ? "eye" : "eye.slash")
                    }

                    // 会话导航：多次练习时显示前后切换
                    if sessionIndices.count > 1 {
                        let pos = (sessionIndices.firstIndex(of: currentSessionIndex) ?? 0) + 1
                        let total = sessionIndices.count
                        HStack(spacing: 2) {
                            Button {
                                navigateSession(offset: -1)
                            } label: {
                                Image(systemName: "chevron.left")
                            }
                            .disabled(sessionIndices.first == currentSessionIndex)

                            Text("第\(pos)次")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(pos < total ? .secondary : .primary)
                                .animation(.none, value: currentSessionIndex)

                            Button {
                                navigateSession(offset: 1)
                            } label: {
                                Image(systemName: "chevron.right")
                            }
                            .disabled(sessionIndices.last == currentSessionIndex)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("第\(pos)次，共\(total)次")
                    }

                    Menu {
                        Text("答题内容独立保存，不写入原 PDF")

                        Button {
                            startNewSession()
                        } label: {
                            Label("新建练习", systemImage: "plus.circle")
                        }

                        Button {
                            isSessionManagerPresented = true
                        } label: {
                            Label("管理练习记录", systemImage: "list.bullet.rectangle")
                        }
                        .disabled(sessionIndices.count < 2)

                        Divider()

                        Button(role: .destructive) {
                            isClearAnswersConfirmationPresented = true
                        } label: {
                            Label("清除本次答题", systemImage: "trash")
                        }
                    } label: {
                        Label("答题管理", systemImage: "ellipsis.circle")
                    }

                    Button {
                        isWritingEnabled = false
                        isScratchPresented = true
                    } label: {
                        Label("草稿板", systemImage: "scribble.variable")
                    }

                    Button {
                        if isSelectionMode {
                            leaveSelectionMode()
                        } else {
                            isWritingEnabled = false
                            isSelectionMode = true
                        }
                    } label: {
                        Label(
                            isSelectionMode ? "退出框选" : "框选",
                            systemImage: isSelectionMode ? "xmark" : "viewfinder"
                        )
                    }
                    .tint(isSelectionMode ? .orange : .accentColor)
                }
            }
        }
        .onAppear {
            do {
                try StorageService.makePDFReadOnly(at: document.localFileURL)
            } catch {
                alert = AppAlert(title: "无法保护原 PDF", error: error)
            }
            loadSavedAnswers()
        }
        .onDisappear {
            pendingSaveTask?.cancel()
            persistModelContext()
        }
        .sheet(item: $currentCard) { card in
            NavigationStack {
                MistakeCardEditorView(card: card)
            }
        }
        .sheet(item: $aiAnalysisRequest) { request in
            AIAnalysisView(image: request.image)
        }
        .sheet(item: $shareImageRequest) { request in
            NavigationStack {
                VStack(spacing: 24) {
                    if let image = request.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 420)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    ShareLink(
                        item: request,
                        preview: SharePreview(
                            "PaperClip 题目截图",
                            image: request.image.map(Image.init(uiImage:))
                                ?? Image(systemName: "photo")
                        )
                    ) {
                        Label("打开系统分享菜单", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(24)
                .navigationTitle("分享题目截图")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("关闭") { shareImageRequest = nil }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isPDFPageExportPresented) {
            PDFPageExportView(
                documentURL: document.localFileURL,
                drawings: drawings,
                canvasSizes: canvasSizes
            )
        }
        .sheet(isPresented: $isSessionManagerPresented) {
            PracticeSessionManagerView(
                sessions: makePracticeSessionItems(),
                currentSessionIndex: currentSessionIndex,
                onDelete: deleteSessions(at:)
            )
        }
        .alert(item: $alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("好"))
            )
        }
        .confirmationDialog(
            "清除全部答题？",
            isPresented: $isClearAnswersConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("清除本次答题", role: .destructive) {
                clearAllAnswers()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将清除第\(currentSessionIndex)次的所有手写内容，其他次练习记录不受影响。此操作不可撤销。")
        }
    }

    private func saveDrawing(pageIndex: Int, data: Data) {
        drawings[pageIndex] = data
        if let layer = handwritingByPage[pageIndex] {
            layer.drawingData = data
            layer.updatedAt = .now
        } else {
            let layer = HandwritingLayer(
                documentId: document.id,
                pageIndex: pageIndex,
                drawingData: data,
                sessionIndex: currentSessionIndex
            )
            modelContext.insert(layer)
            handwritingByPage[pageIndex] = layer
        }
        scheduleModelContextSave()
    }

    /// 清除当前会话的所有手写内容，不影响其他会话。
    private func clearAllAnswers() {
        let currentSession = currentSessionIndex
        for layer in handwritingByPage.values where layer.sessionIndex == currentSession {
            modelContext.delete(layer)
        }
        for layer in handwritingLayers where layer.sessionIndex == currentSession
            && handwritingByPage[layer.pageIndex] == nil {
            modelContext.delete(layer)
        }
        drawings.removeAll()
        handwritingByPage.removeAll()
        clearAnswersToken += 1
        pendingSaveTask?.cancel()
        persistModelContext()
    }

    private func loadSavedAnswers() {
        let bySession = groupLayersBySession()
        sessionIndices = bySession.keys.sorted().nonEmpty ?? [1]
        currentSessionIndex = sessionIndices.last ?? 1
        applySession(from: bySession, index: currentSessionIndex, cleanDuplicates: true)
    }

    private func groupLayersBySession() -> [Int: [HandwritingLayer]] {
        var result: [Int: [HandwritingLayer]] = [:]
        for layer in handwritingLayers {
            result[layer.sessionIndex, default: []].append(layer)
        }
        return result
    }

    /// 将指定会话的笔迹加载到视图状态。cleanDuplicates 为 true 时删除同会话内的重复 layer。
    private func applySession(
        from bySession: [Int: [HandwritingLayer]],
        index: Int,
        cleanDuplicates: Bool
    ) {
        var latestByPage: [Int: HandwritingLayer] = [:]
        let sorted = (bySession[index] ?? []).sorted { $0.updatedAt < $1.updatedAt }
        for layer in sorted {
            if cleanDuplicates, let older = latestByPage[layer.pageIndex] {
                modelContext.delete(older)
            }
            latestByPage[layer.pageIndex] = layer
        }
        handwritingByPage = latestByPage
        drawings = latestByPage.mapValues(\.drawingData)
        if cleanDuplicates { persistModelContext() }
    }

    /// 开始全新一次练习（session 递增，画布清空）。
    private func startNewSession() {
        pendingSaveTask?.cancel()
        persistModelContext()
        let newIndex = (sessionIndices.max() ?? 0) + 1
        sessionIndices.append(newIndex)
        currentSessionIndex = newIndex
        handwritingByPage = [:]
        drawings = [:]
        reloadDrawingsToken += 1
    }

    /// 相邻会话导航（offset: -1 上一次，+1 下一次）。
    private func navigateSession(offset: Int) {
        guard let pos = sessionIndices.firstIndex(of: currentSessionIndex) else { return }
        let newPos = pos + offset
        guard sessionIndices.indices.contains(newPos) else { return }
        switchToSession(sessionIndices[newPos])
    }

    /// 切换到指定历史会话（保存当前，加载目标）。
    private func switchToSession(_ index: Int) {
        guard sessionIndices.contains(index) else { return }
        pendingSaveTask?.cancel()
        persistModelContext()
        currentSessionIndex = index
        let bySession = groupLayersBySession()
        applySession(from: bySession, index: index, cleanDuplicates: false)
        reloadDrawingsToken += 1
    }

    /// 删除指定 sessionIndex 的所有 HandwritingLayer，并更新会话列表。
    private func deleteSessions(at indices: [Int]) {
        pendingSaveTask?.cancel()

        let toDelete = Set(indices)
        for layer in handwritingLayers where toDelete.contains(layer.sessionIndex) {
            modelContext.delete(layer)
        }
        sessionIndices.removeAll { toDelete.contains($0) }

        if sessionIndices.isEmpty {
            // 全删光：保留一个空白会话
            sessionIndices = [1]
            currentSessionIndex = 1
            drawings.removeAll()
            handwritingByPage.removeAll()
        } else if toDelete.contains(currentSessionIndex) {
            // 当前会话被删：切换到最新
            currentSessionIndex = sessionIndices.last ?? 1
            let bySession = groupLayersBySession()
            applySession(from: bySession, index: currentSessionIndex, cleanDuplicates: false)
        }

        reloadDrawingsToken += 1
        persistModelContext()
    }

    /// 生成供 PracticeSessionManagerView 使用的会话摘要列表。
    private func makePracticeSessionItems() -> [PracticeSessionItem] {
        let bySession = groupLayersBySession()
        return sessionIndices.enumerated().map { displayIndex, rawIndex in
            let layers = bySession[rawIndex] ?? []
            let earliest = layers.map(\.createdAt).min() ?? .now
            return PracticeSessionItem(
                rawIndex: rawIndex,
                displayNumber: displayIndex + 1,
                pageCount: Set(layers.map(\.pageIndex)).count,
                createdAt: earliest
            )
        }
    }

    private func persistModelContext() {
        do {
            try modelContext.save()
        } catch {
            alert = AppAlert(title: "保存答题失败", error: error)
        }
    }

    private func scheduleModelContextSave() {
        pendingSaveTask?.cancel()
        pendingSaveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            persistModelContext()
            pendingSaveTask = nil
        }
    }

    private func leaveSelectionMode() {
        guard isSelectionMode else { return }
        selectionRect = nil
        isSelectionMode = false
    }

    private func selectionRectDidChange(_ rect: CGRect?) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            selectionRect = rect
        }
    }

    private func performSelectionAction(_ action: PDFSelectionAction) {
        pendingSelectionAction = action
        selectionActionToken += 1
    }

    private func resetSelection() {
        pendingSelectionAction = nil
        cancelSelectionToken += 1
    }

    private func handleSelectionAction(
        image: UIImage,
        width: Double,
        height: Double,
        action: PDFSelectionAction
    ) {
        // 延迟状态更新，避免在 updateUIView 内部同步修改触发 SwiftUI 重建
        let captured = image
        switch action {
        case .analyze:
            Task { @MainActor in
                isSelectionMode = false
                aiAnalysisRequest = AIAnalysisRequest(image: captured)
            }
        case .share:
            Task { @MainActor in
                isSelectionMode = false
                guard let data = captured.pngData() else {
                    alert = AppAlert(
                        title: "无法分享截图",
                        message: "截图无法转换为 PNG 数据。"
                    )
                    return
                }
                shareImageRequest = ShareImageRequest(data: data)
            }
        case .saveMistake:
            do {
                let fileName = try StorageService.saveCardImage(image)
                let card = MistakeCard(
                    imageFileName: fileName,
                    originalWidth: width,
                    originalHeight: height,
                    recognitionStatus: RecognitionStatus.pending.rawValue,
                    sourceDocumentTitle: document.title
                )
                modelContext.insert(card)
                do {
                    // 后台服务会从持久层回查卡片，因此必须先保存再入队。
                    try modelContext.save()
                } catch {
                    modelContext.delete(card)
                    StorageService.deleteFile(at: card.imageURL)
                    throw error
                }

                // 后台静默识别：持久化成功后立即入队，不阻塞界面。
                MistakeCardRecognitionService.shared.enqueue(
                    cardID: card.id,
                    imagePath: card.imageURL.path
                )
                currentCard = card
                isSelectionMode = false
            } catch {
                alert = AppAlert(title: "保存错题截图失败", error: error)
            }
        }
    }
}

// MARK: - 框选菜单栏

private struct SelectionMenuBar: View {
    let onSave: () -> Void
    let onAnalyze: () -> Void
    let onShare: () -> Void
    let onReselect: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            menuButton("收藏错题", icon: "rectangle.stack.badge.plus", action: onSave)
            Divider().frame(height: 20)
            menuButton("AI 解析", icon: "brain", action: onAnalyze)
            Divider().frame(height: 20)
            menuButton("分享截图", icon: "square.and.arrow.up", action: onShare)
            Divider().frame(height: 20)
            menuButton("重新选取", icon: "arrow.clockwise", action: onReselect)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
    }

    private func menuButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderless)
    }
}

// MARK: - 练习记录管理

struct PracticeSessionItem: Identifiable {
    let rawIndex: Int       // 存储在 HandwritingLayer.sessionIndex 中的真实值
    let displayNumber: Int  // 用户可见的序号（1、2、3…）
    let pageCount: Int
    let createdAt: Date
    var id: Int { rawIndex }
}

struct PracticeSessionManagerView: View {
    let sessions: [PracticeSessionItem]
    let currentSessionIndex: Int
    let onDelete: ([Int]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editMode: EditMode = .inactive
    @State private var selectedIDs: Set<Int> = []
    @State private var pendingDeleteIDs: [Int] = []
    @State private var isDeleteConfirmationPresented = false

    var body: some View {
        NavigationStack {
            List(selection: $selectedIDs) {
                ForEach(sessions) { item in
                    PracticeSessionRow(
                        item: item,
                        isCurrent: item.rawIndex == currentSessionIndex
                    )
                    .tag(item.rawIndex)
                    .accessibilityLabel("第\(item.displayNumber)次练习，\(item.pageCount)页")
                }
                .onDelete { indexSet in
                    pendingDeleteIDs = indexSet.map { sessions[$0].rawIndex }
                    isDeleteConfirmationPresented = true
                }
            }
            .environment(\.editMode, $editMode)
            .navigationTitle("练习记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(editMode == .active ? "取消" : "选择") {
                        withAnimation {
                            editMode = editMode == .active ? .inactive : .active
                        }
                        selectedIDs.removeAll()
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    if editMode == .active, !selectedIDs.isEmpty {
                        Button(role: .destructive) {
                            pendingDeleteIDs = Array(selectedIDs)
                            isDeleteConfirmationPresented = true
                        } label: {
                            Text("删除已选（\(selectedIDs.count) 次）")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .confirmationDialog(
                "删除 \(pendingDeleteIDs.count) 次练习记录？",
                isPresented: $isDeleteConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("删除", role: .destructive) {
                    onDelete(pendingDeleteIDs)
                    dismiss()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("此操作不可撤销，历史手写内容将永久删除。")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct PracticeSessionRow: View {
    let item: PracticeSessionItem
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("第\(item.displayNumber)次")
                        .font(.headline)
                    if isCurrent {
                        Text("当前")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.accentColor, in: Capsule())
                    }
                }
                Text(
                    item.createdAt,
                    format: .dateTime.year().month().day().hour().minute()
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text(item.pageCount == 0 ? "空白" : "\(item.pageCount) 页")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

// MARK: - Helpers

private extension Array {
    /// 为空时返回 nil，方便与 ?? 配合使用。
    var nonEmpty: [Element]? { isEmpty ? nil : self }
}


// MARK: - 几何画板数据模型（点优先架构）
//
// 业务需求说明（均无系统等价实现）：
// 1. 透明度可调的浮动面板
// 2. 方格/点阵网格背景
// 3. 点优先几何图形绘制：GeoPoint 是独立实体，GeoShape 通过 pointIDs 引用点
//    移动点时所有依赖该点的图形自动更新（无需额外代码）
// 4. 已有点标签修改（A–Z, α–ω 等），不创建独立文字对象
// 已评估：辅助功能、深色模式、多窗口、系统手势、Apple Pencil 分流。

struct GeoStyle {
    var color: Color = .blue
    var lineWidth: CGFloat = 2
}

struct GeoPoint: Identifiable, Equatable {
    var id = UUID()
    var position: CGPoint
    var label: String
}

enum GeoShapeKind {
    case segment           // pointIDs: [p1, p2]
    case circle            // pointIDs: [center, rim]
    case polygon           // pointIDs: [v0...vN], 闭合多边形
    case arrow             // pointIDs: [from, to]
    case rightAngleMark    // pointIDs: [arm1, vertex, arm2]
    case angleMark         // pointIDs: [arm1, vertex, arm2]
}

struct GeoShape: Identifiable {
    var id = UUID()
    var kind: GeoShapeKind
    var pointIDs: [UUID]
    var style: GeoStyle
}

struct GeoCanvas {
    var points: [GeoPoint] = []
    var shapes: [GeoShape] = []

    func point(_ id: UUID) -> GeoPoint? { points.first { $0.id == id } }
    func pos(_ id: UUID) -> CGPoint { point(id)?.position ?? .zero }

    private var usedLabels: Set<String> { Set(points.map(\.label)) }

    mutating func nextLabel() -> String {
        let used = usedLabels
        for ch in "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map(String.init) {
            if !used.contains(ch) { return ch }
        }
        var n = 1; while used.contains("P\(n)") { n += 1 }; return "P\(n)"
    }

    @discardableResult
    mutating func addPoint(at position: CGPoint, automaticallyLabel: Bool = true) -> GeoPoint {
        let p = GeoPoint(position: position, label: automaticallyLabel ? nextLabel() : "")
        points.append(p)
        return p
    }

    @discardableResult
    /// 仅复用坐标实际重合的点。是否吸附由手势层决定，避免自由放置时因临近旧点而被隐式合并。
    mutating func getOrCreatePoint(
        near position: CGPoint,
        threshold: CGFloat = 1,
        automaticallyLabelNewPoint: Bool = true
    ) -> GeoPoint {
        if let existing = nearestPoint(to: position, threshold: threshold) { return existing }
        return addPoint(at: position, automaticallyLabel: automaticallyLabelNewPoint)
    }

    func nearestPoint(to position: CGPoint, threshold: CGFloat = 22) -> GeoPoint? {
        points.filter {
            hypot($0.position.x - position.x, $0.position.y - position.y) < threshold
        }.min {
            hypot($0.position.x - position.x, $0.position.y - position.y) <
            hypot($1.position.x - position.x, $1.position.y - position.y)
        }
    }

    mutating func delete(pointIDs delPIDs: Set<UUID>, shapeIDs delSIDs: Set<UUID>) {
        let cascade = Set(shapes.filter { s in s.pointIDs.contains { delPIDs.contains($0) } }.map(\.id))
        shapes.removeAll { delSIDs.contains($0.id) || cascade.contains($0.id) }
        points.removeAll { delPIDs.contains($0.id) }
    }

    private func distToSeg(_ pt: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let projected = projectedPoint(pt, onSegmentFrom: a, to: b)
        return hypot(pt.x - projected.x, pt.y - projected.y)
    }

    private func projectedPoint(_ pt: CGPoint, onSegmentFrom a: CGPoint, to b: CGPoint) -> CGPoint {
        let dx = b.x - a.x, dy = b.y - a.y, sq = dx * dx + dy * dy
        guard sq > 0 else { return a }
        let t = max(0, min(1, ((pt.x - a.x) * dx + (pt.y - a.y) * dy) / sq))
        return CGPoint(x: a.x + t * dx, y: a.y + t * dy)
    }

    /// 返回距离触点最近的已有线条位置。包括线段、箭头、多边形边、角的两条边和圆周。
    func nearestLinePosition(
        to pt: CGPoint,
        excludingPoint: UUID? = nil,
        threshold: CGFloat
    ) -> CGPoint? {
        var bestPosition: CGPoint?
        var bestDistance = threshold

        func consider(_ candidate: CGPoint) {
            let distance = hypot(candidate.x - pt.x, candidate.y - pt.y)
            if distance < bestDistance {
                bestDistance = distance
                bestPosition = candidate
            }
        }

        func considerSegment(_ a: CGPoint, _ b: CGPoint) {
            consider(projectedPoint(pt, onSegmentFrom: a, to: b))
        }

        for shape in shapes {
            if let excludingPoint, shape.pointIDs.contains(excludingPoint) {
                continue
            }

            let positions = shape.pointIDs.compactMap { point($0)?.position }
            switch shape.kind {
            case .segment, .arrow:
                guard positions.count >= 2 else { continue }
                considerSegment(positions[0], positions[1])

            case .polygon:
                guard positions.count >= 2 else { continue }
                for index in positions.indices {
                    considerSegment(positions[index], positions[(index + 1) % positions.count])
                }

            case .rightAngleMark, .angleMark:
                guard positions.count >= 3 else { continue }
                considerSegment(positions[0], positions[1])
                considerSegment(positions[1], positions[2])

            case .circle:
                guard positions.count >= 2 else { continue }
                let center = positions[0]
                let rim = positions[1]
                let radius = hypot(rim.x - center.x, rim.y - center.y)
                let distanceToCenter = hypot(pt.x - center.x, pt.y - center.y)
                guard radius > 0, distanceToCenter > 0 else { continue }
                consider(
                    CGPoint(
                        x: center.x + (pt.x - center.x) / distanceToCenter * radius,
                        y: center.y + (pt.y - center.y) / distanceToCenter * radius
                    )
                )

            }
        }

        return bestPosition
    }

    func hitShape(at pt: CGPoint, threshold: CGFloat = 14) -> UUID? {
        for shape in shapes.reversed() {
            let pp = shape.pointIDs.compactMap { point($0)?.position }
            switch shape.kind {
            case .segment, .arrow:
                guard pp.count >= 2, distToSeg(pt, pp[0], pp[1]) < threshold else { continue }
                return shape.id
            case .circle:
                guard pp.count >= 2 else { continue }
                let r = hypot(pp[1].x - pp[0].x, pp[1].y - pp[0].y)
                guard abs(hypot(pt.x - pp[0].x, pt.y - pp[0].y) - r) < threshold else { continue }
                return shape.id
            case .polygon:
                let hit = (0..<pp.count).contains { i in
                    distToSeg(pt, pp[i], pp[(i + 1) % pp.count]) < threshold
                }
                if hit { return shape.id }
            case .rightAngleMark, .angleMark:
                guard pp.count >= 2, distToSeg(pt, pp[0], pp[1]) < threshold else { continue }
                return shape.id
            }
        }
        return nil
    }
}

enum GeoDrawingTool: String, CaseIterable, Identifiable {
    case pan        = "pan"
    case pointer    = "pointer"
    case point      = "point"
    case segment    = "segment"
    case circle     = "circle"
    case triangle   = "triangle"
    case arrow      = "arrow"
    case rightAngle = "rightAngle"
    case angleMark  = "angleMark"
    case editLabel  = "editLabel"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pan:        return "拖动画布"
        case .pointer:    return "选择"
        case .point:      return "点"
        case .segment:    return "线段"
        case .circle:     return "圆"
        case .triangle:   return "三角形"
        case .arrow:      return "箭头"
        case .rightAngle: return "直角"
        case .angleMark:  return "角"
        case .editLabel:  return "改字母"
        }
    }

    var sfSymbol: String {
        switch self {
        case .pan:        return "hand.draw"
        case .pointer:    return "cursorarrow"
        case .point:      return "circle.fill"
        case .segment:    return "line.diagonal"
        case .circle:     return "circle"
        case .triangle:   return "triangle"
        case .arrow:      return "arrow.up.right"
        case .rightAngle: return "l.square"
        case .angleMark:  return "angle"
        case .editLabel:  return "character.textbox"
        }
    }

    var requiredPoints: Int {
        switch self {
        case .pan, .pointer, .point, .editLabel: return 0
        case .segment, .circle, .arrow: return 2
        case .triangle, .rightAngle, .angleMark: return 3
        }
    }
}

enum GeoInteractionState {
    case idle
    case draggingPoint(id: UUID)
    case staging(positions: [CGPoint], preview: CGPoint?)

    var stagedPositions: [CGPoint] {
        if case .staging(let p, _) = self { return p }
        return []
    }
    var previewPos: CGPoint? {
        if case .staging(_, let p) = self { return p }
        return nil
    }
}

enum GeoSnapKind {
    case none
    case point
    case line
    case grid
}

struct SnapResult {
    var position: CGPoint
    var snapToPointID: UUID?
    var kind: GeoSnapKind
}

enum ScratchGridStyle: String, CaseIterable {
    case none   = "无网格"
    case square = "方格"
    case dot    = "点阵"
}

// MARK: - FloatingScratchBoard
//
// 自定义理由：
// - SwiftUI/PencilKit 无浮动可移动画布
// - 无内置透明度调节、网格背景、几何图形绘制能力
// - 点优先架构：GeoPoint 独立存储，图形通过 pointIDs 引用，移动点时图形自动更新

struct FloatingScratchBoard: View {
    let onClose: () -> Void

    // 面板布局
    @State private var clearToken = 0
    @State private var panelSize = CGSize(width: 720, height: 440)
    @State private var panelCenter: CGPoint?
    @GestureState private var moveTranslation: CGSize = .zero
    @GestureState private var resizeTranslation: CGSize = .zero

    // 背景
    @State private var backgroundOpacity: Double = 0.92
    @State private var showOpacitySlider = false

    // 网格
    @State private var gridStyle: ScratchGridStyle = .none
    @State private var gridSpacing: CGFloat = 24

    // 几何画板状态
    @State private var canvas = GeoCanvas()
    @State private var undoStack: [GeoCanvas] = []
    @State private var redoStack: [GeoCanvas] = []
    @State private var isGeometricMode = false
    @State private var currentTool: GeoDrawingTool = .pointer
    @State private var interactionState: GeoInteractionState = .idle
    @State private var snapResult: SnapResult? = nil
    @State private var selectedIDs: Set<UUID> = []
    @State private var shapeStyle = GeoStyle()
    @State private var dragSnapshot: GeoCanvas? = nil
    @State private var selectedLetter: String = "A"
    @State private var isSnappingEnabled = true
    @State private var snapToExistingPoints = true
    @State private var snapToExistingLines = true
    @State private var snapToGrid = true
    @State private var bypassSnapOnce = false
    @State private var viewportOrigin = CGPoint.zero

    private let lineWidthOptions: [CGFloat] = [1, 1.5, 2, 3, 4]
    private let pointSnapDistance: CGFloat = 18
    private let lineSnapDistance: CGFloat = 12
    private let gridSnapDistance: CGFloat = 7
    private let geometryLetters: [String] = [
        "A","B","C","D","E","F","G","H","I","M","N","O","P","Q","R","S","T","X","Y","Z",
        "α","β","γ","θ","φ","ω","°","′","∠","⊥","∥"
    ]
    private var canUseGeometricMode: Bool { gridStyle != .none }

    // MARK: 快照 / Undo

    private func pushUndo() {
        undoStack.append(canvas)
        redoStack.removeAll()
        if undoStack.count > 30 { undoStack.removeFirst() }
    }

    private func undo() {
        guard let prev = undoStack.popLast() else { return }
        redoStack.append(canvas)
        canvas = prev
        selectedIDs = []
        interactionState = .idle
        snapResult = nil
    }

    private func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(canvas)
        canvas = next
    }

    private func deleteSelected() {
        guard !selectedIDs.isEmpty else { return }
        pushUndo()
        let pids = Set(canvas.points.filter { selectedIDs.contains($0.id) }.map(\.id))
        let sids = Set(canvas.shapes.filter { selectedIDs.contains($0.id) }.map(\.id))
        canvas.delete(pointIDs: pids, shapeIDs: sids)
        selectedIDs = []
    }

    // MARK: 吸附

    private func computeSnap(for pt: CGPoint, excludingPoint: UUID? = nil) -> SnapResult {
        guard isSnappingEnabled, !bypassSnapOnce else {
            return SnapResult(position: pt, snapToPointID: nil, kind: .none)
        }

        // 1. 已有点吸附（最高优先级）
        if snapToExistingPoints {
            let candidates = canvas.points.filter {
                $0.id != excludingPoint &&
                hypot($0.position.x - pt.x, $0.position.y - pt.y) < pointSnapDistance
            }
            if let nearest = candidates.min(by: {
                hypot($0.position.x - pt.x, $0.position.y - pt.y) <
                hypot($1.position.x - pt.x, $1.position.y - pt.y)
            }) {
                return SnapResult(position: nearest.position, snapToPointID: nearest.id, kind: .point)
            }
        }

        // 2. 已有线条吸附：把新点放到最近线段、圆周或多边形边上。
        if snapToExistingLines,
           let linePosition = canvas.nearestLinePosition(
               to: pt,
               excludingPoint: excludingPoint,
               threshold: lineSnapDistance
           ) {
            return SnapResult(position: linePosition, snapToPointID: nil, kind: .line)
        }

        // 3. 网格仅在接近交点时吸附，不再强制将所有坐标取整。
        if snapToGrid, gridStyle != .none {
            let snapped = CGPoint(
                x: round(pt.x / gridSpacing) * gridSpacing,
                y: round(pt.y / gridSpacing) * gridSpacing
            )
            if hypot(snapped.x - pt.x, snapped.y - pt.y) <= gridSnapDistance {
                return SnapResult(position: snapped, snapToPointID: nil, kind: .grid)
            }
        }

        return SnapResult(position: pt, snapToPointID: nil, kind: .none)
    }

    /// 字母工具只允许修改已有标签，不受绘图吸附设置影响。
    private func editableLabelPoint(near pt: CGPoint) -> GeoPoint? {
        canvas.points
            .filter {
                !$0.label.isEmpty &&
                hypot($0.position.x - pt.x, $0.position.y - pt.y) < pointSnapDistance + 6
            }
            .min {
                hypot($0.position.x - pt.x, $0.position.y - pt.y) <
                hypot($1.position.x - pt.x, $1.position.y - pt.y)
            }
    }

    private func modelPoint(from viewportPoint: CGPoint) -> CGPoint {
        CGPoint(
            x: viewportPoint.x + viewportOrigin.x,
            y: viewportPoint.y + viewportOrigin.y
        )
    }

    // MARK: 手势路由

    func handleGestureStart(_ pt: CGPoint) {
        let modelPoint = modelPoint(from: pt)

        if currentTool == .editLabel {
            if let point = editableLabelPoint(near: modelPoint) {
                snapResult = SnapResult(position: point.position, snapToPointID: point.id, kind: .point)
            } else {
                snapResult = nil
            }
            return
        }

        let snap = computeSnap(for: modelPoint)
        snapResult = snap

        switch currentTool {
        case .pointer:
            if let pid = snap.snapToPointID {
                selectedIDs = [pid]
                dragSnapshot = canvas
                interactionState = .draggingPoint(id: pid)
            } else if let sid = canvas.hitShape(at: modelPoint) {
                selectedIDs = [sid]
                interactionState = .idle
            } else {
                selectedIDs = []
                interactionState = .idle
            }
        default:
            break
        }
    }

    func handleGestureMove(_ pt: CGPoint) {
        let modelPoint = modelPoint(from: pt)

        if currentTool == .editLabel {
            if let point = editableLabelPoint(near: modelPoint) {
                snapResult = SnapResult(position: point.position, snapToPointID: point.id, kind: .point)
            } else {
                snapResult = nil
            }
            interactionState = .idle
            return
        }

        var excludeID: UUID? = nil
        if case .draggingPoint(let id) = interactionState { excludeID = id }

        let snap = computeSnap(for: modelPoint, excludingPoint: excludeID)
        snapResult = snap

        switch interactionState {
        case .draggingPoint(let id):
            if let idx = canvas.points.firstIndex(where: { $0.id == id }) {
                canvas.points[idx].position = snap.position
            }
        case .staging(let positions, _):
            interactionState = .staging(positions: positions, preview: snap.position)
        case .idle:
            if currentTool != .pointer {
                interactionState = .staging(positions: [], preview: snap.position)
            }
        }
    }

    func handleGestureEnd(_ pt: CGPoint, isTap: Bool) {
        // 指针工具拖拽结束
        if case .draggingPoint = interactionState {
            if let snapshot = dragSnapshot {
                if canvas.points != snapshot.points {
                    undoStack.append(snapshot)
                    redoStack.removeAll()
                } else {
                    canvas = snapshot   // 恢复：没有实际移动
                }
                dragSnapshot = nil
            }
            interactionState = .idle
            snapResult = nil
            return
        }

        guard isTap else {
            if case .staging(let positions, _) = interactionState {
                interactionState = .staging(positions: positions, preview: nil)
            }
            return
        }

        let modelPoint = modelPoint(from: pt)
        let snap = computeSnap(for: modelPoint)

        switch currentTool {
        case .pan:
            break

        case .pointer:
            break   // 选择在 gestureStart 完成

        case .point:
            if let pointID = snap.snapToPointID {
                selectedIDs = [pointID]
            } else {
                pushUndo()
                canvas.addPoint(at: snap.position)
            }
            interactionState = .idle

        case .segment, .circle, .arrow:
            let staged = interactionState.stagedPositions
            if staged.isEmpty {
                interactionState = .staging(positions: [snap.position], preview: nil)
            } else {
                let second = snap.position
                guard hypot(staged[0].x - second.x, staged[0].y - second.y) > 4 else { break }
                pushUndo()
                let automaticallyLabelNewPoints = currentTool != .arrow
                let p1 = canvas.getOrCreatePoint(
                    near: staged[0],
                    automaticallyLabelNewPoint: automaticallyLabelNewPoints
                )
                let p2 = canvas.getOrCreatePoint(
                    near: second,
                    automaticallyLabelNewPoint: automaticallyLabelNewPoints
                )
                let kind: GeoShapeKind = currentTool == .circle ? .circle :
                                          currentTool == .arrow  ? .arrow  : .segment
                canvas.shapes.append(GeoShape(kind: kind, pointIDs: [p1.id, p2.id], style: shapeStyle))
                interactionState = .idle
            }

        case .triangle, .rightAngle, .angleMark:
            var newStaged = interactionState.stagedPositions
            newStaged.append(snap.position)
            if newStaged.count < currentTool.requiredPoints {
                interactionState = .staging(positions: newStaged, preview: nil)
            } else {
                pushUndo()
                let automaticallyLabelNewPoints = currentTool == .triangle
                let pts = newStaged.map {
                    canvas.getOrCreatePoint(
                        near: $0,
                        automaticallyLabelNewPoint: automaticallyLabelNewPoints
                    )
                }
                let kind: GeoShapeKind = currentTool == .triangle   ? .polygon :
                                          currentTool == .rightAngle ? .rightAngleMark : .angleMark
                canvas.shapes.append(GeoShape(kind: kind, pointIDs: pts.map(\.id), style: shapeStyle))
                interactionState = .idle
            }

        case .editLabel:
            if let point = editableLabelPoint(near: modelPoint),
               point.label != selectedLetter,
               let index = canvas.points.firstIndex(where: { $0.id == point.id }) {
                pushUndo()
                canvas.points[index].label = selectedLetter
                selectedIDs = [point.id]
            }
            interactionState = .idle
        }

        if currentTool != .pointer && currentTool != .editLabel {
            bypassSnapOnce = false
        }
        snapResult = nil
    }

    // MARK: 主体

    var body: some View {
        GeometryReader { geometry in
            let availableSize = geometry.size
            let displayedSize = effectiveSize(in: availableSize)
            let displayedCenter = effectiveCenter(panelSize: displayedSize, in: availableSize)

            VStack(spacing: 0) {
                titleBar(in: availableSize)

                if isGeometricMode {
                    geometricToolBar
                }

                ZStack(alignment: .bottomTrailing) {
                    Color.white.opacity(backgroundOpacity)

                    if gridStyle != .none {
                        ScratchGridLayer(
                            style: gridStyle,
                            spacing: gridSpacing,
                            viewportOrigin: viewportOrigin
                        )
                            .opacity(0.5)
                            .allowsHitTesting(false)
                    }

                    ScratchCanvas(
                        clearToken: clearToken,
                        viewportOrigin: viewportOrigin
                    )
                        .background(Color.clear)

                    GeoCanvasLayer(
                        canvas: canvas,
                        selectedIDs: selectedIDs,
                        interactionState: interactionState,
                        snapResult: snapResult,
                        currentTool: currentTool,
                        shapeStyle: shapeStyle,
                        gridSpacing: gridSpacing,
                        viewportOrigin: $viewportOrigin,
                        isActive: isGeometricMode,
                        onGestureStart: handleGestureStart,
                        onGestureMove: handleGestureMove,
                        onGestureEnd: handleGestureEnd
                    )

                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 38, height: 38)
                        .background(.regularMaterial, in: Circle())
                        .contentShape(Rectangle())
                        .padding(6)
                        .gesture(resizeGesture(in: availableSize))
                        .accessibilityLabel("调整草稿板大小")
                }
                .overlay(alignment: .top) {
                    VStack(spacing: 6) {
                        constructionStatusOverlay
                        selectionStatusOverlay
                    }
                    .padding(.top, 8)
                }
            }
            .frame(width: displayedSize.width, height: displayedSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.quaternary, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
            .position(displayedCenter)
            .transaction { $0.animation = nil }
            .onAppear {
                panelSize = constrainedSize(panelSize, in: availableSize)
                if panelCenter == nil { panelCenter = defaultCenter(in: availableSize) }
            }
            .onChange(of: availableSize) { _, newSize in
                panelSize = constrainedSize(panelSize, in: newSize)
                panelCenter = constrainedCenter(
                    panelCenter ?? defaultCenter(in: newSize),
                    panelSize: panelSize, in: newSize
                )
            }
            .onChange(of: currentTool) { _, _ in
                interactionState = .idle
                snapResult = nil
            }
            .onChange(of: isGeometricMode) { _, isOn in
                if !isOn {
                    interactionState = .idle
                    snapResult = nil
                    selectedIDs = []
                    bypassSnapOnce = false
                }
            }
        }
    }

    // MARK: 标题栏

    @ViewBuilder
    private func titleBar(in availableSize: CGSize) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "scribble.variable").foregroundStyle(.blue)
                Text("草稿板").font(.headline)
                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { showOpacitySlider.toggle() }
                } label: {
                    Image(systemName: "circle.lefthalf.filled")
                }
                .foregroundStyle(showOpacitySlider ? .blue : .secondary)
                .accessibilityLabel("透明度调节")

                Menu {
                    ForEach(ScratchGridStyle.allCases, id: \.self) { style in
                        Button {
                            gridStyle = style
                            if style == .none && isGeometricMode { isGeometricMode = false }
                        } label: {
                            HStack {
                                Text(style.rawValue)
                                if gridStyle == style { Image(systemName: "checkmark") }
                            }
                        }
                    }

                    Divider()

                    Button {
                        viewportOrigin = .zero
                    } label: {
                        Label("画布归位", systemImage: "scope")
                    }
                    .disabled(viewportOrigin == .zero)
                } label: {
                    Image(systemName: gridStyle == .none ? "grid" : "grid.circle.fill")
                        .foregroundStyle(gridStyle != .none ? .blue : .secondary)
                }
                .accessibilityLabel("网格样式")

                Button {
                    guard canUseGeometricMode else { return }
                    withAnimation(.easeInOut(duration: 0.18)) { isGeometricMode.toggle() }
                } label: {
                    Image(systemName: isGeometricMode ? "triangle.circle.fill" : "triangle.circle")
                }
                .foregroundStyle(isGeometricMode ? Color.blue : Color.secondary)
                .disabled(!canUseGeometricMode)
                .accessibilityLabel(canUseGeometricMode ? "几何画图模式" : "请先开启网格")

                Menu {
                    Button(role: .destructive) { clearToken += 1 } label: {
                        Label("清空手写", systemImage: "scribble")
                    }
                    Button(role: .destructive) {
                        pushUndo(); canvas = GeoCanvas()
                        selectedIDs = []; interactionState = .idle
                    } label: {
                        Label("清空几何图形", systemImage: "triangle")
                    }
                    Button(role: .destructive) {
                        clearToken += 1
                        pushUndo(); canvas = GeoCanvas()
                        selectedIDs = []; interactionState = .idle
                    } label: {
                        Label("全部清空", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "trash").foregroundStyle(.secondary)
                }
                .accessibilityLabel("清空草稿板")

                Button(action: onClose) { Image(systemName: "xmark") }
                    .accessibilityLabel("关闭草稿板")
            }
            .padding(.horizontal, 14)
            .frame(height: 50)

            if showOpacitySlider {
                HStack(spacing: 10) {
                    Image(systemName: "sun.min").foregroundStyle(.secondary).font(.caption)
                    Slider(value: $backgroundOpacity, in: 0.0...1.0, step: 0.01)
                    Image(systemName: "sun.max").foregroundStyle(.secondary).font(.caption)
                    Text("\(Int(backgroundOpacity * 100))%")
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
                .padding(.horizontal, 14).padding(.bottom, 8)
            }
        }
        .background(.regularMaterial)
        .contentShape(Rectangle())
        .gesture(moveGesture(in: availableSize))
    }

    // MARK: 几何工具栏

    private var geometricToolBar: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    // 工具按钮
                    ForEach(GeoDrawingTool.allCases) { tool in
                        Button { currentTool = tool } label: {
                            VStack(spacing: 2) {
                                Image(systemName: tool.sfSymbol).font(.system(size: 15))
                                Text(tool.displayName).font(.system(size: 9))
                            }
                            .frame(minWidth: 44).padding(.vertical, 6)
                            .background(
                                currentTool == tool ? Color.blue.opacity(0.15) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(currentTool == tool ? Color.blue : Color.clear, lineWidth: 1)
                            )
                        }
                        .foregroundStyle(currentTool == tool ? .blue : .primary)
                        .accessibilityLabel(tool.displayName)
                    }

                    Divider().frame(height: 28)

                    ColorPicker("", selection: $shapeStyle.color, supportsOpacity: false)
                        .labelsHidden().frame(width: 32, height: 32)
                        .accessibilityLabel("图形颜色")

                    Menu {
                        ForEach(lineWidthOptions, id: \.self) { w in
                            Button { shapeStyle.lineWidth = w } label: {
                                HStack {
                                    Text("\(w, specifier: "%.1f") pt")
                                    if shapeStyle.lineWidth == w { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "lineweight")
                            Text("\(shapeStyle.lineWidth, specifier: "%.0f")pt").font(.caption)
                        }.foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("线条粗细")

                    Menu {
                        Toggle("启用智能吸附", isOn: $isSnappingEnabled)

                        Section("吸附目标") {
                            Toggle("已有点", isOn: $snapToExistingPoints)
                            Toggle("已有线条与圆周", isOn: $snapToExistingLines)
                            Toggle("网格或点阵", isOn: $snapToGrid)
                        }

                        Divider()

                        Button {
                            bypassSnapOnce.toggle()
                            snapResult = nil
                        } label: {
                            Label(
                                bypassSnapOnce ? "取消下一点自由放置" : "下一点自由放置",
                                systemImage: bypassSnapOnce ? "checkmark.circle.fill" : "hand.tap"
                            )
                        }
                        .disabled(!isSnappingEnabled)
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "scope")
                            Text(bypassSnapOnce ? "自由" : "吸附")
                                .font(.system(size: 9))
                        }
                        .frame(minWidth: 38)
                        .foregroundStyle(
                            bypassSnapOnce || !isSnappingEnabled ? Color.orange : Color.secondary
                        )
                    }
                    .accessibilityLabel("吸附设置")
                    .accessibilityValue(
                        bypassSnapOnce ? "下一点自由放置" : isSnappingEnabled ? "已启用" : "已关闭"
                    )

                    Divider().frame(height: 28)

                    // 撤销
                    Button { undo() } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .foregroundStyle(undoStack.isEmpty ? .tertiary : .secondary)
                    .disabled(undoStack.isEmpty)
                    .accessibilityLabel("撤销")

                    // 重做
                    Button { redo() } label: {
                        Image(systemName: "arrow.uturn.forward")
                    }
                    .foregroundStyle(redoStack.isEmpty ? .tertiary : .secondary)
                    .disabled(redoStack.isEmpty)
                    .accessibilityLabel("重做")
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
            }
            .frame(height: 54)

            // 已有点标签修改
            if currentTool == .editLabel {
                letterPalette
            }

        }
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var constructionStatusOverlay: some View {
        let stagedCount = interactionState.stagedPositions.count
        if stagedCount > 0 && currentTool != .pointer {
            HStack(spacing: 8) {
                Label(constructionHint(staged: stagedCount), systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()
                    .frame(height: 14)

                Button {
                    interactionState = .idle
                    snapResult = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
                .accessibilityLabel("取消当前图形")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        }
    }

    @ViewBuilder
    private var selectionStatusOverlay: some View {
        if currentTool == .pointer && !selectedIDs.isEmpty {
            let selPoint = canvas.points.first { selectedIDs.contains($0.id) }
            let selShape = canvas.shapes.first { selectedIDs.contains($0.id) }
            HStack(spacing: 8) {
                if let p = selPoint {
                    Image(systemName: "circle.fill").font(.caption).foregroundStyle(.orange)
                    Text(p.label.isEmpty ? "控制点·拖动可移动" : "点 \(p.label)·拖动可移动")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if selShape != nil {
                    Image(systemName: "checkmark.circle").font(.caption).foregroundStyle(.blue)
                    Text("已选中图形·拖动可移动").font(.caption).foregroundStyle(.secondary)
                }

                Divider().frame(height: 14)

                Button(role: .destructive) { deleteSelected() } label: {
                    Image(systemName: "trash")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
                .accessibilityLabel("删除选中元素")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        }
    }

    private func constructionHint(staged: Int) -> String {
        switch currentTool {
        case .segment: return "点击第 2 个点完成线段"
        case .circle:  return "点击第 2 个点确定半径"
        case .arrow:   return "点击第 2 个点完成箭头"
        case .triangle:
            return staged == 1 ? "已放置 1/3 个顶点" : "已放置 2/3 个顶点，点击第 3 个"
        case .rightAngle:
            return staged == 1 ? "点击直角顶点" : "点击第 2 条边的端点"
        case .angleMark:
            return staged == 1 ? "点击角的顶点" : "点击第 2 条边的端点"
        case .editLabel: return "点击已有字母进行替换"
        default: return ""
        }
    }

    private var letterPalette: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Label("点击已有字母，替换为", systemImage: "hand.tap")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                ForEach(geometryLetters, id: \.self) { letter in
                    Button { selectedLetter = letter } label: {
                        Text(letter)
                            .font(.system(size: 16, weight: .medium, design: .serif))
                            .frame(width: 32, height: 32)
                            .background(
                                selectedLetter == letter ? Color.blue.opacity(0.15) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 6)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        selectedLetter == letter ? Color.blue : Color.secondary.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .foregroundStyle(selectedLetter == letter ? .blue : .primary)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
        }
        .frame(height: 48)
    }

    // MARK: 面板手势

    private func moveGesture(in availableSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .updating($moveTranslation) { value, state, _ in state = value.translation }
            .onEnded { value in
                let displayedSize = effectiveSize(in: availableSize)
                let start = panelCenter ?? defaultCenter(in: availableSize)
                panelCenter = constrainedCenter(
                    CGPoint(x: start.x + value.translation.width, y: start.y + value.translation.height),
                    panelSize: displayedSize, in: availableSize
                )
            }
    }

    private func resizeGesture(in availableSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .updating($resizeTranslation) { value, state, _ in state = value.translation }
            .onEnded { value in
                let startSize = panelSize
                let startCenter = panelCenter ?? defaultCenter(in: availableSize)
                let newSize = constrainedSize(
                    CGSize(width: startSize.width + value.translation.width,
                           height: startSize.height + value.translation.height),
                    in: availableSize
                )
                let delta = CGSize(width: newSize.width - startSize.width, height: newSize.height - startSize.height)
                panelSize = newSize
                panelCenter = constrainedCenter(
                    CGPoint(x: startCenter.x + delta.width / 2, y: startCenter.y + delta.height / 2),
                    panelSize: newSize, in: availableSize
                )
            }
    }

    private func effectiveSize(in availableSize: CGSize) -> CGSize {
        constrainedSize(
            CGSize(width: panelSize.width + resizeTranslation.width,
                   height: panelSize.height + resizeTranslation.height),
            in: availableSize
        )
    }

    private func effectiveCenter(panelSize displayedSize: CGSize, in availableSize: CGSize) -> CGPoint {
        let baseCenter = panelCenter ?? defaultCenter(in: availableSize)
        return constrainedCenter(
            CGPoint(
                x: baseCenter.x + moveTranslation.width + (displayedSize.width - panelSize.width) / 2,
                y: baseCenter.y + moveTranslation.height + (displayedSize.height - panelSize.height) / 2
            ),
            panelSize: displayedSize, in: availableSize
        )
    }

    private func defaultCenter(in availableSize: CGSize) -> CGPoint {
        CGPoint(x: availableSize.width * 0.68, y: availableSize.height * 0.34)
    }

    private func constrainedSize(_ size: CGSize, in availableSize: CGSize) -> CGSize {
        CGSize(
            width: min(max(size.width, 280), max(280, availableSize.width - 24)),
            height: min(max(size.height, 200), max(200, availableSize.height - 24))
        )
    }

    private func constrainedCenter(_ center: CGPoint, panelSize: CGSize, in availableSize: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(center.x, panelSize.width / 2 + 12), availableSize.width - panelSize.width / 2 - 12),
            y: min(max(center.y, panelSize.height / 2 + 12), availableSize.height - panelSize.height / 2 - 12)
        )
    }
}

// MARK: - 网格背景层
// SwiftUI Canvas 是官方推荐的自定义 2D 绘制 API，无 UIKit 包装，
// 支持深色模式（Color.primary）和任意尺寸缩放。

private struct ScratchGridLayer: View {
    let style: ScratchGridStyle
    let spacing: CGFloat
    let viewportOrigin: CGPoint

    var body: some View {
        GeometryReader { geo in
            Canvas { context, _ in
                let size = geo.size
                switch style {
                case .none: break
                case .square: drawSquare(context: context, size: size)
                case .dot:    drawDot(context: context, size: size)
                }
            }
        }
    }

    private func drawSquare(context: GraphicsContext, size: CGSize) {
        var path = Path()
        var x = firstGridPosition(for: viewportOrigin.x)
        while x < size.width { path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height)); x += spacing }
        var y = firstGridPosition(for: viewportOrigin.y)
        while y < size.height { path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y)); y += spacing }
        context.stroke(path, with: .color(.init(white: 0, opacity: 0.18)), lineWidth: 0.5)
    }

    private func drawDot(context: GraphicsContext, size: CGSize) {
        var path = Path()
        var x = firstGridPosition(for: viewportOrigin.x)
        while x < size.width {
            var y = firstGridPosition(for: viewportOrigin.y)
            while y < size.height { path.addEllipse(in: CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3)); y += spacing }
            x += spacing
        }
        context.fill(path, with: .color(.init(white: 0, opacity: 0.3)))
    }

    private func firstGridPosition(for origin: CGFloat) -> CGFloat {
        var position = (-origin).truncatingRemainder(dividingBy: spacing)
        if position <= 0 { position += spacing }
        return position
    }
}

// MARK: - 几何图形渲染层
// 业务需求：点优先几何图形绘制。PencilKit 无预设形状 API。
// drawingPolicy = .pencilOnly 保证 Pencil 由 PK 处理，手指由此层处理。
// GeoPoint 是独立实体，图形通过 pointIDs 引用；渲染时动态解析坐标。

private struct GeoCanvasLayer: View {
    let canvas: GeoCanvas
    let selectedIDs: Set<UUID>
    let interactionState: GeoInteractionState
    let snapResult: SnapResult?
    let currentTool: GeoDrawingTool
    let shapeStyle: GeoStyle
    let gridSpacing: CGFloat
    @Binding var viewportOrigin: CGPoint
    let isActive: Bool
    let onGestureStart: (CGPoint) -> Void
    let onGestureMove: (CGPoint) -> Void
    let onGestureEnd: (CGPoint, Bool) -> Void

    @State private var gestureActive = false
    @State private var panOriginAtStart: CGPoint?

    private let viewportLimit: CGFloat = 2_048

    var body: some View {
        Canvas { context, size in
            context.translateBy(x: -viewportOrigin.x, y: -viewportOrigin.y)
            renderShapes(ctx: &context)
            renderPoints(ctx: &context)
            renderPreview(ctx: &context)
            renderSnapIndicator(ctx: &context)
        }
        .contentShape(Rectangle())
        .allowsHitTesting(isActive)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    if currentTool == .pan {
                        let startOrigin = panOriginAtStart ?? viewportOrigin
                        if panOriginAtStart == nil {
                            panOriginAtStart = viewportOrigin
                        }
                        viewportOrigin = constrainedViewportOrigin(
                            CGPoint(
                                x: startOrigin.x - value.translation.width,
                                y: startOrigin.y - value.translation.height
                            )
                        )
                        return
                    }

                    if !gestureActive {
                        gestureActive = true
                        onGestureStart(value.startLocation)
                    }
                    onGestureMove(value.location)
                }
                .onEnded { value in
                    if currentTool == .pan {
                        let startOrigin = panOriginAtStart ?? viewportOrigin
                        viewportOrigin = constrainedViewportOrigin(
                            CGPoint(
                                x: startOrigin.x - value.translation.width,
                                y: startOrigin.y - value.translation.height
                            )
                        )
                        panOriginAtStart = nil
                        gestureActive = false
                        return
                    }

                    let isTap = hypot(value.translation.width, value.translation.height) < 8
                    onGestureEnd(value.location, isTap)
                    gestureActive = false
                },
            including: isActive ? .all : .none
        )
        .accessibilityLabel("几何绘图区域")
        .accessibilityHint(
            currentTool == .pan
                ? "单指拖动以移动画布"
                : "使用手指放置或移动控制点，Apple Pencil 用于手写"
        )
        .onChange(of: currentTool) { _, _ in
            panOriginAtStart = nil
            gestureActive = false
        }
    }

    // MARK: 图形渲染

    private func renderShapes(ctx: inout GraphicsContext) {
        for shape in canvas.shapes {
            renderShape(shape, ctx: &ctx)
        }
    }

    private func renderShape(_ shape: GeoShape, ctx: inout GraphicsContext) {
        let isSelected = selectedIDs.contains(shape.id)
        let style = shape.style
        let lw = isSelected ? style.lineWidth + 1 : style.lineWidth
        let shading = GraphicsContext.Shading.color(style.color)
        let pp = shape.pointIDs.compactMap { canvas.point($0)?.position }

        switch shape.kind {
        case .segment:
            guard pp.count >= 2 else { return }
            var path = Path()
            path.move(to: pp[0]); path.addLine(to: pp[1])
            ctx.stroke(path, with: shading, lineWidth: lw)
            if isSelected { renderSegmentMeasure(pp[0], pp[1], ctx: &ctx) }

        case .arrow:
            guard pp.count >= 2 else { return }
            var path = Path()
            path.move(to: pp[0]); path.addLine(to: pp[1])
            let len = hypot(pp[1].x - pp[0].x, pp[1].y - pp[0].y)
            if len > 0 {
                let ux = (pp[1].x - pp[0].x) / len, uy = (pp[1].y - pp[0].y) / len
                let wl = min(16, len * 0.35), a: CGFloat = .pi / 6
                let ca = cos(a), sa = sin(a)
                path.move(to: pp[1])
                path.addLine(to: CGPoint(x: pp[1].x - wl*(ux*ca - uy*sa), y: pp[1].y - wl*(uy*ca + ux*sa)))
                path.move(to: pp[1])
                path.addLine(to: CGPoint(x: pp[1].x - wl*(ux*ca + uy*sa), y: pp[1].y - wl*(uy*ca - ux*sa)))
            }
            ctx.stroke(path, with: shading, lineWidth: lw)

        case .circle:
            guard pp.count >= 2 else { return }
            let r = hypot(pp[1].x - pp[0].x, pp[1].y - pp[0].y)
            var path = Path()
            path.addEllipse(in: CGRect(x: pp[0].x - r, y: pp[0].y - r, width: r * 2, height: r * 2))
            ctx.stroke(path, with: shading, lineWidth: lw)
            if isSelected { renderCircleMeasure(center: pp[0], rim: pp[1], ctx: &ctx) }

        case .polygon:
            guard pp.count >= 3 else { return }
            var path = Path()
            path.move(to: pp[0])
            pp.dropFirst().forEach { path.addLine(to: $0) }
            path.closeSubpath()
            ctx.stroke(path, with: shading, lineWidth: lw)

        case .rightAngleMark:
            guard pp.count >= 3 else { return }
            let arm1 = pp[0], vertex = pp[1], arm2 = pp[2]
            var path = Path()
            path.move(to: arm1); path.addLine(to: vertex)
            path.move(to: arm2); path.addLine(to: vertex)
            ctx.stroke(path, with: shading, lineWidth: lw)
            // 直角小方块
            let sq: CGFloat = 11
            let d1 = normalize(arm1, from: vertex)
            let d2 = normalize(arm2, from: vertex)
            var sqPath = Path()
            sqPath.move(to: CGPoint(x: vertex.x + d1.x * sq, y: vertex.y + d1.y * sq))
            sqPath.addLine(to: CGPoint(x: vertex.x + d1.x * sq + d2.x * sq, y: vertex.y + d1.y * sq + d2.y * sq))
            sqPath.addLine(to: CGPoint(x: vertex.x + d2.x * sq, y: vertex.y + d2.y * sq))
            ctx.stroke(sqPath, with: shading, lineWidth: lw)

        case .angleMark:
            guard pp.count >= 3 else { return }
            let arm1 = pp[0], vertex = pp[1], arm2 = pp[2]
            var path = Path()
            path.move(to: arm1); path.addLine(to: vertex)
            path.move(to: arm2); path.addLine(to: vertex)
            ctx.stroke(path, with: shading, lineWidth: lw)
            let r1 = hypot(arm1.x - vertex.x, arm1.y - vertex.y)
            let r2 = hypot(arm2.x - vertex.x, arm2.y - vertex.y)
            let arcR = min(r1, r2) * 0.35
            if arcR > 4 {
                let a1 = atan2(arm1.y - vertex.y, arm1.x - vertex.x)
                let a2 = atan2(arm2.y - vertex.y, arm2.x - vertex.x)
                var sweep = a2 - a1
                while sweep > .pi { sweep -= 2 * .pi }
                while sweep <= -.pi { sweep += 2 * .pi }
                var arcPath = Path()
                arcPath.addArc(center: vertex, radius: arcR,
                               startAngle: .radians(a1), endAngle: .radians(a2),
                               clockwise: sweep < 0)
                ctx.stroke(arcPath, with: shading, lineWidth: lw)
                // 角度标注
                if isSelected {
                    let deg = abs(sweep) * 180 / .pi
                    let midA = a1 + sweep / 2
                    let labelPt = CGPoint(x: vertex.x + (arcR + 10) * cos(midA),
                                         y: vertex.y + (arcR + 10) * sin(midA))
                    ctx.draw(
                        Text("\(Int(deg.rounded()))°")
                            .font(.system(size: 11).monospacedDigit())
                            .foregroundStyle(style.color),
                        at: labelPt, anchor: .center
                    )
                }
            }

        }

        // 选中高亮：控制点小方块
        if isSelected {
            for pos in pp {
                var h = Path()
                h.addRect(CGRect(x: pos.x - 4, y: pos.y - 4, width: 8, height: 8))
                ctx.fill(h, with: .color(.white))
                ctx.stroke(h, with: shading, lineWidth: 1.5)
            }
        }
    }

    private func renderSegmentMeasure(_ p1: CGPoint, _ p2: CGPoint, ctx: inout GraphicsContext) {
        let len = hypot(p2.x - p1.x, p2.y - p1.y) / gridSpacing
        let dx = p2.x - p1.x, dy = p2.y - p1.y
        let d = hypot(dx, dy)
        guard d > 0 else { return }
        let nx = -dy / d, ny = dx / d
        let mid = CGPoint(x: (p1.x + p2.x) / 2 + nx * 13, y: (p1.y + p2.y) / 2 + ny * 13)
        ctx.draw(
            Text(String(format: "%.1f", len))
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(Color.secondary),
            at: mid, anchor: .center
        )
    }

    private func renderCircleMeasure(center: CGPoint, rim: CGPoint, ctx: inout GraphicsContext) {
        let r = hypot(rim.x - center.x, rim.y - center.y) / gridSpacing
        ctx.draw(
            Text("r=\(String(format: "%.1f", r))")
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(Color.secondary),
            at: CGPoint(x: rim.x + 6, y: rim.y - 6), anchor: .bottomLeading
        )
    }

    // MARK: 点渲染

    private func renderPoints(ctx: inout GraphicsContext) {
        for point in canvas.points {
            let isSelected = selectedIDs.contains(point.id)
            let pos = point.position
            let r: CGFloat = isSelected ? 6 : 5

            // 白色外圈保证控制点不会被深色线条或网格吞没。
            var halo = Path()
            halo.addEllipse(
                in: CGRect(
                    x: pos.x - r - 2,
                    y: pos.y - r - 2,
                    width: (r + 2) * 2,
                    height: (r + 2) * 2
                )
            )
            ctx.fill(halo, with: .color(.white.opacity(0.95)))
            ctx.stroke(halo, with: .color(.black.opacity(0.22)), lineWidth: 1)

            var dot = Path()
            dot.addEllipse(in: CGRect(x: pos.x - r, y: pos.y - r, width: r * 2, height: r * 2))
            ctx.fill(dot, with: .color(isSelected ? .orange : .blue))

            // 选中圆环
            if isSelected {
                var ring = Path()
                ring.addEllipse(in: CGRect(x: pos.x - 9, y: pos.y - 9, width: 18, height: 18))
                ctx.stroke(ring, with: .color(.orange), lineWidth: 1.5)
            }

            // 标签
            if !point.label.isEmpty {
                ctx.draw(
                    Text(point.label)
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundStyle(Color.black),
                    at: CGPoint(x: pos.x + 7, y: pos.y - 7), anchor: .bottomLeading
                )
            }
        }
    }

    // MARK: 预览虚线

    private func renderPreview(ctx: inout GraphicsContext) {
        let staged = interactionState.stagedPositions
        let previewShading = GraphicsContext.Shading.color(shapeStyle.color.opacity(0.5))
        let dashed = StrokeStyle(lineWidth: shapeStyle.lineWidth, dash: [5, 3])

        // 临时顶点必须在抬手后继续显示，否则多点图形无法准确放置后续顶点。
        for (index, point) in staged.enumerated() {
            var halo = Path()
            halo.addEllipse(in: CGRect(x: point.x - 8, y: point.y - 8, width: 16, height: 16))
            ctx.fill(halo, with: .color(.white.opacity(0.95)))
            ctx.stroke(halo, with: .color(shapeStyle.color.opacity(0.9)), lineWidth: 2)

            var dot = Path()
            dot.addEllipse(in: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8))
            ctx.fill(dot, with: .color(shapeStyle.color))

            ctx.draw(
                Text("\(index + 1)")
                    .font(.system(size: 10, weight: .bold).monospacedDigit())
                    .foregroundStyle(Color.black),
                at: CGPoint(x: point.x + 10, y: point.y - 10),
                anchor: .bottomLeading
            )
        }

        guard let preview = interactionState.previewPos else { return }
        var path = Path()

        switch currentTool {
        case .segment, .arrow, .circle:
            guard staged.count == 1 else { return }
            path.move(to: staged[0]); path.addLine(to: preview)
            ctx.stroke(path, with: previewShading, style: dashed)

        case .triangle:
            if staged.count == 1 {
                path.move(to: staged[0]); path.addLine(to: preview)
            } else if staged.count == 2 {
                path.move(to: staged[0]); path.addLine(to: staged[1])
                path.move(to: staged[1]); path.addLine(to: preview)
                path.move(to: preview);   path.addLine(to: staged[0])
            }
            ctx.stroke(path, with: previewShading, style: dashed)

        case .rightAngle, .angleMark:
            if staged.count >= 1 {
                path.move(to: staged[0]); path.addLine(to: preview)
            }
            if staged.count >= 2 {
                path.move(to: staged[1]); path.addLine(to: preview)
            }
            ctx.stroke(path, with: previewShading, style: dashed)

        default: break
        }

        // 当前待放置点使用空心圆，和已经确认的临时顶点区分。
        var cursor = Path()
        cursor.addEllipse(in: CGRect(x: preview.x - 6, y: preview.y - 6, width: 12, height: 12))
        ctx.fill(cursor, with: .color(.white.opacity(0.8)))
        ctx.stroke(cursor, with: .color(shapeStyle.color.opacity(0.85)), lineWidth: 2)
    }

    // MARK: 吸附指示器

    private func renderSnapIndicator(ctx: inout GraphicsContext) {
        guard let snap = snapResult else { return }
        let pos = snap.position
        switch snap.kind {
        case .point:
            var ring = Path()
            ring.addEllipse(in: CGRect(x: pos.x - 11, y: pos.y - 11, width: 22, height: 22))
            ctx.stroke(ring, with: .color(.yellow.opacity(0.85)), lineWidth: 2)

        case .line:
            var diamond = Path()
            diamond.move(to: CGPoint(x: pos.x, y: pos.y - 8))
            diamond.addLine(to: CGPoint(x: pos.x + 8, y: pos.y))
            diamond.addLine(to: CGPoint(x: pos.x, y: pos.y + 8))
            diamond.addLine(to: CGPoint(x: pos.x - 8, y: pos.y))
            diamond.closeSubpath()
            ctx.stroke(diamond, with: .color(.green.opacity(0.9)), lineWidth: 2)

        case .grid:
            var cross = Path()
            cross.move(to: CGPoint(x: pos.x - 6, y: pos.y)); cross.addLine(to: CGPoint(x: pos.x + 6, y: pos.y))
            cross.move(to: CGPoint(x: pos.x, y: pos.y - 6)); cross.addLine(to: CGPoint(x: pos.x, y: pos.y + 6))
            ctx.stroke(cross, with: .color(.blue.opacity(0.55)), lineWidth: 1.5)

        case .none:
            break
        }
    }

    // MARK: 辅助

    private func normalize(_ point: CGPoint, from origin: CGPoint) -> CGPoint {
        let dx = point.x - origin.x, dy = point.y - origin.y
        let len = hypot(dx, dy)
        guard len > 0 else { return .zero }
        return CGPoint(x: dx / len, y: dy / len)
    }

    private func constrainedViewportOrigin(_ origin: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(origin.x, -viewportLimit), viewportLimit),
            y: min(max(origin.y, -viewportLimit), viewportLimit)
        )
    }
}

// MARK: - PencilKit 手写画布

private struct ScratchCanvas: UIViewRepresentable {
    let clearToken: Int
    let viewportOrigin: CGPoint

    private let virtualCanvasOrigin = CGPoint(x: 2_048, y: 2_048)
    private let virtualCanvasSize = CGSize(width: 6_144, height: 6_144)

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .pencilOnly
        canvas.isScrollEnabled = false
        canvas.bounces = false
        canvas.contentInsetAdjustmentBehavior = .never
        canvas.contentSize = virtualCanvasSize
        canvas.contentOffset = virtualCanvasOrigin
        canvas.tool = PKInkingTool(.pen, color: .systemBlue, width: 3)
        context.coordinator.attach(to: canvas)
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        canvas.contentSize = virtualCanvasSize
        let targetOffset = CGPoint(
            x: virtualCanvasOrigin.x + viewportOrigin.x,
            y: virtualCanvasOrigin.y + viewportOrigin.y
        )
        if hypot(
            canvas.contentOffset.x - targetOffset.x,
            canvas.contentOffset.y - targetOffset.y
        ) > 0.5 {
            canvas.setContentOffset(targetOffset, animated: false)
        }

        context.coordinator.showToolPicker(for: canvas)
        if context.coordinator.lastClearToken != clearToken {
            canvas.drawing = PKDrawing()
            context.coordinator.lastClearToken = clearToken
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    static func dismantleUIView(_ canvas: PKCanvasView, coordinator: Coordinator) {
        coordinator.detach(from: canvas)
    }

    @MainActor
    final class Coordinator {
        var lastClearToken = 0
        private let toolPicker = PKToolPicker()
        private weak var canvas: PKCanvasView?

        init() { toolPicker.stateAutosaveName = "PaperClip.ScratchTools" }

        func attach(to canvas: PKCanvasView) {
            self.canvas = canvas
            toolPicker.addObserver(canvas)
            showToolPicker(for: canvas)
        }

        func showToolPicker(for canvas: PKCanvasView) {
            guard canvas.window != nil else { return }
            canvas.becomeFirstResponder()
            toolPicker.setVisible(true, forFirstResponder: canvas)
        }

        func detach(from canvas: PKCanvasView) {
            toolPicker.setVisible(false, forFirstResponder: canvas)
            toolPicker.removeObserver(canvas)
            canvas.resignFirstResponder()
            self.canvas = nil
        }
    }
}
