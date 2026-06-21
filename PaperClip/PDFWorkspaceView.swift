import SwiftUI
import SwiftData
import PencilKit
import UniformTypeIdentifiers

struct ShareImageRequest: Identifiable, Transferable, Sendable {
    let id = UUID()
    let data: Data

    var image: UIImage? { UIImage(data: data) }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { request in
            request.data
        }
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

/// SwiftUI 与 PencilKit 没有提供可移动、可调整尺寸的浮动画布容器。
/// 此视图仅自定义容器移动和缩放，书写、工具、橡皮与套索仍由
/// PKCanvasView/PKToolPicker 提供；拖动手势只附加在标题栏和缩放手柄，
/// 不拦截画布内 Apple Pencil 输入，也不改变底层 PDF 的滚动与缩放手势。
struct FloatingScratchBoard: View {
    let onClose: () -> Void

    @State private var clearToken = 0
    @State private var panelSize = CGSize(width: 560, height: 420)
    @State private var panelCenter: CGPoint?
    @GestureState private var moveTranslation: CGSize = .zero
    @GestureState private var resizeTranslation: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            let availableSize = geometry.size
            let displayedSize = effectiveSize(in: availableSize)
            let displayedCenter = effectiveCenter(
                panelSize: displayedSize,
                in: availableSize
            )

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "scribble.variable")
                        .foregroundStyle(.blue)

                    Text("草稿板")
                        .font(.headline)

                    Spacer()

                    Button {
                        clearToken += 1
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("清空草稿板")

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("关闭草稿板")
                }
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(.regularMaterial)
                .contentShape(Rectangle())
                .gesture(moveGesture(in: availableSize))

                ZStack(alignment: .bottomTrailing) {
                    Color.white.opacity(0.78)

                    ScratchCanvas(clearToken: clearToken)
                        .background(Color.clear)

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
            }
            .frame(width: displayedSize.width, height: displayedSize.height)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.quaternary, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.16), radius: 18, y: 8)
            .position(displayedCenter)
            .transaction { transaction in
                transaction.animation = nil
            }
            .onAppear {
                panelSize = constrainedSize(panelSize, in: availableSize)
                if panelCenter == nil {
                    panelCenter = defaultCenter(in: availableSize)
                }
            }
            .onChange(of: availableSize) { _, newSize in
                panelSize = constrainedSize(panelSize, in: newSize)
                panelCenter = constrainedCenter(
                    panelCenter ?? defaultCenter(in: newSize),
                    panelSize: panelSize,
                    in: newSize
                )
            }
        }
    }

    private func moveGesture(in availableSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .updating($moveTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let displayedSize = effectiveSize(in: availableSize)
                let start = panelCenter ?? defaultCenter(in: availableSize)
                panelCenter = constrainedCenter(
                    CGPoint(
                        x: start.x + value.translation.width,
                        y: start.y + value.translation.height
                    ),
                    panelSize: displayedSize,
                    in: availableSize
                )
            }
    }

    private func resizeGesture(in availableSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .updating($resizeTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let startSize = panelSize
                let startCenter = panelCenter ?? defaultCenter(in: availableSize)
                let newSize = constrainedSize(
                    CGSize(
                        width: startSize.width + value.translation.width,
                        height: startSize.height + value.translation.height
                    ),
                    in: availableSize
                )
                let sizeDelta = CGSize(
                    width: newSize.width - startSize.width,
                    height: newSize.height - startSize.height
                )
                panelSize = newSize
                panelCenter = constrainedCenter(
                    CGPoint(
                        x: startCenter.x + sizeDelta.width / 2,
                        y: startCenter.y + sizeDelta.height / 2
                    ),
                    panelSize: newSize,
                    in: availableSize
                )
            }
    }

    private func effectiveSize(in availableSize: CGSize) -> CGSize {
        constrainedSize(
            CGSize(
                width: panelSize.width + resizeTranslation.width,
                height: panelSize.height + resizeTranslation.height
            ),
            in: availableSize
        )
    }

    private func effectiveCenter(
        panelSize displayedSize: CGSize,
        in availableSize: CGSize
    ) -> CGPoint {
        let baseCenter = panelCenter ?? defaultCenter(in: availableSize)
        let resizedWidth = displayedSize.width - panelSize.width
        let resizedHeight = displayedSize.height - panelSize.height

        return constrainedCenter(
            CGPoint(
                x: baseCenter.x + moveTranslation.width + resizedWidth / 2,
                y: baseCenter.y + moveTranslation.height + resizedHeight / 2
            ),
            panelSize: displayedSize,
            in: availableSize
        )
    }

    private func defaultCenter(in availableSize: CGSize) -> CGPoint {
        CGPoint(
            x: availableSize.width * 0.68,
            y: availableSize.height * 0.34
        )
    }

    private func constrainedSize(_ size: CGSize, in availableSize: CGSize) -> CGSize {
        CGSize(
            width: min(max(size.width, 280), max(280, availableSize.width - 24)),
            height: min(max(size.height, 200), max(200, availableSize.height - 24))
        )
    }

    private func constrainedCenter(
        _ center: CGPoint,
        panelSize: CGSize,
        in availableSize: CGSize
    ) -> CGPoint {
        let halfWidth = panelSize.width / 2
        let halfHeight = panelSize.height / 2
        return CGPoint(
            x: min(max(center.x, halfWidth + 12), availableSize.width - halfWidth - 12),
            y: min(max(center.y, halfHeight + 12), availableSize.height - halfHeight - 12)
        )
    }
}

private struct ScratchCanvas: UIViewRepresentable {
    let clearToken: Int

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .pencilOnly
        canvas.isScrollEnabled = false
        canvas.tool = PKInkingTool(.pen, color: .systemBlue, width: 3)
        context.coordinator.attach(to: canvas)
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
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

        init() {
            toolPicker.stateAutosaveName = "PaperClip.ScratchTools"
        }

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
