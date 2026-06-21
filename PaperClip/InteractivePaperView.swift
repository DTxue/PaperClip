import SwiftUI
import SwiftData
import PencilKit

// MARK: - CGRect 解析扩展

extension CGRect {
    /// 从 "x,y,w,h" 格式字符串（值域 0–1）构建 CGRect
    init?(cropString: String) {
        let parts = cropString.split(separator: ",").compactMap { Double($0) }
        guard parts.count == 4 else { return nil }
        self.init(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
    }
}

// MARK: - MistakeCard 题目图片扩展

extension MistakeCard {
    /// 返回展示用图片：优先返回裁剪后的题目区域，无裁剪则返回完整截图
    var questionImage: UIImage? {
        guard let source = UIImage(contentsOfFile: imageURL.path) else { return nil }
        if let cropStr = questionCrop,
           let norm = CGRect(cropString: cropStr),
           norm.width > 0, norm.height > 0,
           let cgImg = source.cgImage?.cropping(to: CGRect(
               x: norm.minX * source.size.width,
               y: norm.minY * source.size.height,
               width: norm.width * source.size.width,
               height: norm.height * source.size.height
           )) {
            return UIImage(cgImage: cgImg, scale: source.scale, orientation: source.imageOrientation)
        }
        return source
    }
}

// MARK: - QuestionCropView（全屏框选题目图片区域）

struct QuestionCropView: View {
    let image: UIImage
    let existingCrop: String?
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    // 归一化选区（0–1 范围）
    @State private var normRect: CGRect
    // 图片在本地坐标系中的实际帧
    @State private var fittedFrame: CGRect = .zero

    // 拖拽状态
    @State private var dragState: CropDragState = .idle
    @State private var dragStartRect: CGRect = .zero
    @State private var dragStartPoint: CGPoint = .zero

    enum CropDragState { case idle, movingBody, resizingTopLeft, resizingTopRight, resizingBottomLeft, resizingBottomRight }

    init(image: UIImage, existingCrop: String?, onSave: @escaping (String) -> Void) {
        self.image = image
        self.existingCrop = existingCrop
        self.onSave = onSave
        if let s = existingCrop, let r = CGRect(cropString: s) {
            _normRect = State(initialValue: r)
        } else {
            _normRect = State(initialValue: CGRect(x: 0.05, y: 0.05, width: 0.9, height: 0.9))
        }
    }

    // 选区在本地坐标系中的绝对矩形
    private var selectionRect: CGRect {
        CGRect(
            x: fittedFrame.minX + normRect.minX * fittedFrame.width,
            y: fittedFrame.minY + normRect.minY * fittedFrame.height,
            width: normRect.width * fittedFrame.width,
            height: normRect.height * fittedFrame.height
        )
    }

    var body: some View {
        GeometryReader { geo in
            let frame = computeFittedFrame(imageSize: image.size, viewSize: geo.size)
            ZStack {
                Color.black

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)

                if fittedFrame != .zero {
                    CropDimmingOverlay(imageFrame: fittedFrame, normRect: normRect)
                        .allowsHitTesting(false)

                    cropInteractionLayer
                }
            }
            .onAppear { fittedFrame = frame }
            .onChange(of: geo.size) { _, newSize in
                fittedFrame = computeFittedFrame(imageSize: image.size, viewSize: newSize)
            }
        }
        .ignoresSafeArea()
        .overlay(alignment: .bottom) { bottomBar }
        .overlay(alignment: .top) {
            Text("拖动边角调整范围，拖动中心移动位置")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.black.opacity(0.5), in: Capsule())
                .padding(.top, 60)
        }
    }

    // MARK: 交互层（移动 + 四角缩放）

    @ViewBuilder
    private var cropInteractionLayer: some View {
        let sel = selectionRect
        let hR: CGFloat = 16
        let minDim: CGFloat = hR * 3

        // 中心拖动区域（可移动整个选框）
        Color.white.opacity(0.001)
            .frame(
                width: max(sel.width - hR * 3, minDim),
                height: max(sel.height - hR * 3, minDim)
            )
            .position(x: sel.midX, y: sel.midY)
            .gesture(moveGesture())
            .accessibilityLabel("拖动移动选区")

        // 四个角手柄
        cornerHandle(at: CGPoint(x: sel.minX, y: sel.minY), state: .resizingTopLeft)
        cornerHandle(at: CGPoint(x: sel.maxX, y: sel.minY), state: .resizingTopRight)
        cornerHandle(at: CGPoint(x: sel.minX, y: sel.maxY), state: .resizingBottomLeft)
        cornerHandle(at: CGPoint(x: sel.maxX, y: sel.maxY), state: .resizingBottomRight)
    }

    private func cornerHandle(at point: CGPoint, state: CropDragState) -> some View {
        let hR: CGFloat = 16
        return ZStack {
            Circle().fill(Color.accentColor).frame(width: hR * 2, height: hR * 2)
            Circle().stroke(Color.white, lineWidth: 2).frame(width: hR * 2, height: hR * 2)
        }
        .shadow(color: .black.opacity(0.3), radius: 3)
        .position(point)
        .gesture(resizeGesture(cornerState: state))
        .accessibilityLabel("调整选区角点")
    }

    // MARK: 拖拽手势

    private func moveGesture() -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if dragState != .movingBody {
                    dragState = .movingBody
                    dragStartRect = normRect
                    dragStartPoint = value.startLocation
                }
                let dx = (value.location.x - dragStartPoint.x) / fittedFrame.width
                let dy = (value.location.y - dragStartPoint.y) / fittedFrame.height
                normRect = clampedNorm(CGRect(
                    x: dragStartRect.minX + dx,
                    y: dragStartRect.minY + dy,
                    width: dragStartRect.width,
                    height: dragStartRect.height
                ))
            }
            .onEnded { _ in dragState = .idle }
    }

    private func resizeGesture(cornerState: CropDragState) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if dragState != cornerState {
                    dragState = cornerState
                    dragStartRect = normRect
                    dragStartPoint = value.startLocation
                }
                let dx = (value.location.x - dragStartPoint.x) / fittedFrame.width
                let dy = (value.location.y - dragStartPoint.y) / fittedFrame.height
                let r = dragStartRect
                let newRect: CGRect
                switch cornerState {
                case .resizingTopLeft:
                    newRect = CGRect(x: r.minX + dx, y: r.minY + dy, width: r.width - dx, height: r.height - dy)
                case .resizingTopRight:
                    newRect = CGRect(x: r.minX, y: r.minY + dy, width: r.width + dx, height: r.height - dy)
                case .resizingBottomLeft:
                    newRect = CGRect(x: r.minX + dx, y: r.minY, width: r.width - dx, height: r.height + dy)
                case .resizingBottomRight:
                    newRect = CGRect(x: r.minX, y: r.minY, width: r.width + dx, height: r.height + dy)
                default:
                    newRect = r
                }
                normRect = clampedNorm(newRect)
            }
            .onEnded { _ in dragState = .idle }
    }

    // MARK: 工具方法

    private func computeFittedFrame(imageSize: CGSize, viewSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        let imgRatio = imageSize.width / imageSize.height
        let viewRatio = viewSize.width / viewSize.height
        let size: CGSize = imgRatio > viewRatio
            ? CGSize(width: viewSize.width, height: viewSize.width / imgRatio)
            : CGSize(width: viewSize.height * imgRatio, height: viewSize.height)
        return CGRect(
            x: (viewSize.width - size.width) / 2,
            y: (viewSize.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }

    private func clampedNorm(_ r: CGRect) -> CGRect {
        let minSize: CGFloat = 0.05
        let x = min(max(r.minX, 0), 1 - minSize)
        let y = min(max(r.minY, 0), 1 - minSize)
        let w = max(min(r.width, 1 - x), minSize)
        let h = max(min(r.height, 1 - y), minSize)
        return CGRect(x: x, y: y, width: w, height: h)
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button("取消") { dismiss() }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.white)

            Spacer()

            if existingCrop != nil {
                Button("清除框选") {
                    onSave("")   // 空字符串信号：调用者设为 nil
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.white)
            }

            Button("重置") {
                normRect = CGRect(x: 0.05, y: 0.05, width: 0.9, height: 0.9)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(.white)

            Button("确认框选") {
                onSave("\(normRect.minX),\(normRect.minY),\(normRect.width),\(normRect.height)")
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial)
    }
}

// MARK: - CropDimmingOverlay（暗化选区外区域）

private struct CropDimmingOverlay: View {
    let imageFrame: CGRect
    let normRect: CGRect

    private var sel: CGRect {
        CGRect(
            x: imageFrame.minX + normRect.minX * imageFrame.width,
            y: imageFrame.minY + normRect.minY * imageFrame.height,
            width: normRect.width * imageFrame.width,
            height: normRect.height * imageFrame.height
        )
    }

    var body: some View {
        ZStack {
            // 上方暗色区域
            dimRect(x: imageFrame.minX, y: imageFrame.minY,
                    w: imageFrame.width,
                    h: max(sel.minY - imageFrame.minY, 0))
            // 下方暗色区域
            dimRect(x: imageFrame.minX, y: sel.maxY,
                    w: imageFrame.width,
                    h: max(imageFrame.maxY - sel.maxY, 0))
            // 左侧暗色区域
            dimRect(x: imageFrame.minX, y: sel.minY,
                    w: max(sel.minX - imageFrame.minX, 0),
                    h: sel.height)
            // 右侧暗色区域
            dimRect(x: sel.maxX, y: sel.minY,
                    w: max(imageFrame.maxX - sel.maxX, 0),
                    h: sel.height)

            // 选区边框
            Rectangle()
                .stroke(Color.accentColor, lineWidth: 2)
                .frame(width: sel.width, height: sel.height)
                .position(x: sel.midX, y: sel.midY)

            // 三分线辅助网格
            let gx = sel.width / 3
            let gy = sel.height / 3
            Path { p in
                [(gx, 0), (gx * 2, 0)].forEach { ox, _ in
                    p.move(to: CGPoint(x: sel.minX + ox, y: sel.minY))
                    p.addLine(to: CGPoint(x: sel.minX + ox, y: sel.maxY))
                }
                [(0, gy), (0, gy * 2)].forEach { _, oy in
                    p.move(to: CGPoint(x: sel.minX, y: sel.minY + oy))
                    p.addLine(to: CGPoint(x: sel.maxX, y: sel.minY + oy))
                }
            }
            .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func dimRect(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) -> some View {
        Color.black.opacity(0.6)
            .frame(width: max(w, 0), height: max(h, 0))
            .position(x: x + max(w, 0) / 2, y: y + max(h, 0) / 2)
    }
}

// MARK: - PaperCardSelectionView（选题出卷）

private struct InteractivePaperSession: Identifiable {
    let id = UUID()
    let cards: [MistakeCard]
}

struct PaperCardSelectionView: View {
    let availableCards: [MistakeCard]
    let subject: String?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedIDs: Set<UUID>
    @State private var filterStatus = "unmastered"
    @State private var activeSession: InteractivePaperSession?

    init(availableCards: [MistakeCard], subject: String?) {
        self.availableCards = availableCards
        self.subject = subject
        let nonMastered = availableCards.filter { $0.status != MasteryStatus.mastered.rawValue }
        _selectedIDs = State(initialValue: Set(nonMastered.map(\.id)))
    }

    private var displayCards: [MistakeCard] {
        switch filterStatus {
        case "unmastered": return availableCards.filter { $0.status == MasteryStatus.unmastered.rawValue }
        case "review":     return availableCards.filter { $0.status == MasteryStatus.review.rawValue }
        case "mastered":   return availableCards.filter { $0.status == MasteryStatus.mastered.rawValue }
        default:           return availableCards
        }
    }

    private var allSelected: Bool { displayCards.allSatisfy { selectedIDs.contains($0.id) } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("范围", selection: $filterStatus) {
                        Text("未掌握").tag("unmastered")
                        Text("待复习").tag("review")
                        Text("已掌握").tag("mastered")
                        Text("全部").tag("all")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: filterStatus) {
                        selectedIDs = Set(displayCards.map(\.id))
                    }
                } header: {
                    Text("选择题目范围")
                } footer: {
                    if selectedIDs.isEmpty {
                        Text("请至少选择 1 道题目。")
                    } else {
                        Text("已选 \(selectedIDs.count) 道题。点击题目可单独取消。")
                    }
                }

                Section {
                    ForEach(displayCards) { card in
                        let isSelected = selectedIDs.contains(card.id)
                        Button {
                            if isSelected { selectedIDs.remove(card.id) }
                            else { selectedIDs.insert(card.id) }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(card.subject)
                                            .font(.subheadline.weight(.medium))
                                        Text(card.resolvedQuestionType.rawValue)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        if !card.tags.isEmpty {
                                            Text(card.tags.prefix(2).joined(separator: " · "))
                                                .font(.caption)
                                                .foregroundStyle(.orange)
                                        }
                                    }
                                    if !card.recognizedText.isEmpty {
                                        Text(card.recognizedText)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    } else {
                                        Text(card.createdAt, format: .dateTime.year().month().day())
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                }

                                Spacer()
                                StatusBadge(status: card.status)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(card.subject) \(isSelected ? "已选" : "未选")")
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
            }
            .navigationTitle("出卷选题\(subject.map { " · \($0)" } ?? "")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("开始（\(selectedIDs.count) 题）") {
                        let cards = availableCards.filter { selectedIDs.contains($0.id) }
                        guard !cards.isEmpty else { return }
                        activeSession = InteractivePaperSession(cards: cards)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedIDs.isEmpty)
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button(allSelected ? "全不选" : "全选") {
                        if allSelected { selectedIDs.removeAll() }
                        else { selectedIDs = Set(displayCards.map(\.id)) }
                    }
                }
            }
        }
        .fullScreenCover(item: $activeSession) { session in
            InteractivePaperView(cards: session.cards, subject: subject)
        }
    }
}

// MARK: - InteractivePaperView（交互试卷主体）

struct InteractivePaperView: View {
    let cards: [MistakeCard]
    let subject: String?

    @Environment(\.dismiss) private var dismiss

    // 每题的手写答案（card.id → PKDrawing）
    @State private var drawings: [UUID: PKDrawing] = [:]
    // 客观题答案（card.id → A/B/C... 或 正确/错误）
    @State private var selectedAnswers: [UUID: String] = [:]
    // 填空题文字答案
    @State private var textAnswers: [UUID: String] = [:]
    // 是否展开到结果页
    @State private var isResultPresented = false
    // 提交确认
    @State private var isSubmitConfirmPresented = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    LazyVGrid(
                        columns: pageColumns(for: geometry.size),
                        alignment: .center,
                        spacing: 16
                    ) {
                        ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                            PaperQuestionItemView(
                                index: index + 1,
                                card: card,
                                drawing: Binding(
                                    get: { drawings[card.id] ?? PKDrawing() },
                                    set: { drawings[card.id] = $0 }
                                ),
                                selectedAnswer: Binding(
                                    get: { selectedAnswers[card.id] ?? "" },
                                    set: { selectedAnswers[card.id] = $0 }
                                ),
                                textAnswer: Binding(
                                    get: { textAnswers[card.id] ?? "" },
                                    set: { textAnswers[card.id] = $0 }
                                )
                            )
                        }
                    }
                    .padding(12)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle(
                subject.map { "\($0) · 交互试卷" } ?? "交互试卷"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("提交试卷") {
                        isSubmitConfirmPresented = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(cards.isEmpty)
                }
            }
            .confirmationDialog(
                "提交 \(cards.count) 道题的答案？",
                isPresented: $isSubmitConfirmPresented,
                titleVisibility: .visible
            ) {
                Button("提交试卷") { isResultPresented = true }
                Button("继续答题", role: .cancel) {}
            } message: {
                Text("提交后进入对答案环节，对照题目自评，结果同步到错题库。")
            }
            .navigationDestination(isPresented: $isResultPresented) {
                PaperResultView(
                    cards: cards,
                    drawings: drawings,
                    selectedAnswers: selectedAnswers,
                    textAnswers: textAnswers,
                    onComplete: { dismiss() }
                )
            }
        }
    }

    private func pageColumns(for size: CGSize) -> [GridItem] {
        let count = size.width > size.height ? 2 : 1
        return Array(
            repeating: GridItem(.flexible(minimum: 0), spacing: 16, alignment: .top),
            count: count
        )
    }
}

// MARK: - PaperQuestionItemView（单题答题卡）

private struct PaperQuestionItemView: View {
    let index: Int
    let card: MistakeCard
    @Binding var drawing: PKDrawing
    @Binding var selectedAnswer: String
    @Binding var textAnswer: String

    @State private var canvasHeight: CGFloat

    init(
        index: Int,
        card: MistakeCard,
        drawing: Binding<PKDrawing>,
        selectedAnswer: Binding<String>,
        textAnswer: Binding<String>
    ) {
        self.index = index
        self.card = card
        _drawing = drawing
        _selectedAnswer = selectedAnswer
        _textAnswer = textAnswer
        _canvasHeight = State(initialValue: Self.initialCanvasHeight(for: card.resolvedQuestionType))
    }

    private var questionType: QuestionType {
        card.resolvedQuestionType
    }

    private var choiceOptionLabels: [String] {
        PaperChoiceParser.optionLabels(
            in: card.recognizedText,
            questionType: questionType
        )
    }

    private var objectiveOptions: [String] {
        switch questionType {
        case .choice: choiceOptionLabels
        case .trueFalse: ["正确", "错误"]
        default: []
        }
    }

    private var isMultipleChoice: Bool {
        guard questionType == .choice else { return false }
        return PaperChoiceParser.isMultipleChoice(
            questionText: card.recognizedText,
            correctAnswer: card.correctAnswer
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 题头
            HStack(spacing: 8) {
                Text("第 \(index) 题")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
                Text(card.subject)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label(questionType.rawValue, systemImage: questionType.systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !card.tags.isEmpty {
                    Text(card.tags.prefix(2).joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                }
                Spacer()
                StatusBadge(status: card.status)
            }

            Divider()

            // 题目文字（OCR 结果）
            if !card.recognizedText.isEmpty {
                RecognitionPreviewView(question: card.recognizedText, isEmbedded: true)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("题目内容：\(card.recognizedText)")
            }

            // 题目图片（裁剪区域或完整截图）
            if let img = card.questionImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: questionImageMaxHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("题目图片")
            }

            answerArea
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
    }

    private var questionImageMaxHeight: CGFloat {
        switch questionType {
        case .reading, .composition: 280
        case .calculation, .proof: 240
        default: 200
        }
    }

    @ViewBuilder
    private var answerArea: some View {
        switch questionType {
        case .choice, .trueFalse:
            objectiveAnswerArea
        case .fillBlank:
            fillBlankAnswerArea
        default:
            handwritingAnswerArea
        }
    }

    private var objectiveAnswerArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                questionType == .trueFalse ? "判断答案" : "选择答案",
                systemImage: questionType.systemImage
            )
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)

            if isMultipleChoice {
                HStack(spacing: 8) {
                    ForEach(objectiveOptions, id: \.self) { option in
                        Toggle(
                            option,
                            isOn: Binding(
                                get: { selectedOptionLabels.contains(option) },
                                set: { updateMultipleChoice(option, isSelected: $0) }
                            )
                        )
                        .toggleStyle(.button)
                        .buttonStyle(.bordered)
                        .accessibilityLabel("选项 \(option)")
                    }
                }
            } else {
                Picker("答案", selection: $selectedAnswer) {
                    Text("未选").tag("")
                    ForEach(objectiveOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("第 \(index) 题答案")
            }
        }
        .padding(.top, 4)
    }

    private var selectedOptionLabels: Set<String> {
        Set(
            selectedAnswer
                .components(separatedBy: CharacterSet(charactersIn: ",，、 "))
                .map { $0.uppercased() }
                .filter { !$0.isEmpty }
        )
    }

    private func updateMultipleChoice(_ option: String, isSelected: Bool) {
        var labels = selectedOptionLabels
        if isSelected {
            labels.insert(option)
        } else {
            labels.remove(option)
        }
        selectedAnswer = objectiveOptions
            .filter { labels.contains($0) }
            .joined(separator: ",")
    }

    private var fillBlankAnswerArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("填写答案", systemImage: QuestionType.fillBlank.systemImage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            TextField("在此填写空格答案", text: $textAnswer, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .accessibilityLabel("第 \(index) 题填空答案")
        }
        .padding(.top, 4)
    }

    private var handwritingAnswerArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("手写答题区", systemImage: "pencil.and.ruler")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    drawing = PKDrawing()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("清除手写")

                Button {
                    canvasHeight += 150
                } label: {
                    Image(systemName: "arrow.down.to.line")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("扩展答题区")
            }

            AnswerCanvas(drawing: $drawing)
                .frame(height: canvasHeight)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
                .accessibilityLabel("手写答题区，第 \(index) 题")
        }
        .padding(.top, 4)
    }

    private static func initialCanvasHeight(for type: QuestionType) -> CGFloat {
        switch type {
        case .reading, .composition: 280
        case .calculation, .proof: 220
        default: 180
        }
    }
}

// Apple 没有从 OCR 文本推断选择题选项的系统 API。
// 此解析器只识别常见 A–H 标记，业务交互仍由 SwiftUI Picker 承担；
// 不引入自定义手势，VoiceOver 使用 Picker 和选项文本的系统语义。
private enum PaperChoiceParser {
    private static let multipleChoiceKeywords = ["多选", "多项选择", "不定项选择"]
    private static let answerPrefixes = ["正确答案", "参考答案", "答案", "选项"]
    private static let answerSeparators = CharacterSet(
        charactersIn: " \t\r\n,，、;；/／|和及与"
    )
    private static let patterns = [
        #"(?m)(?:^|[\r\n])\s*[（(]?([A-Ha-hＡ-Ｈａ-ｈ])[）)]?\s*[\.．、:：]"#,
        #"[（(]([A-Ha-hＡ-Ｈａ-ｈ])[）)]\s*"#,
        #"(?:^|\s)([A-Ha-hＡ-Ｈａ-ｈ])\s*[\.．、:：]\s*"#
    ]

    static func isMultipleChoice(questionText: String, correctAnswer: String) -> Bool {
        if multipleChoiceKeywords.contains(where: { questionText.contains($0) }) {
            return true
        }

        var answer = correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else { return false }

        for prefix in answerPrefixes where answer.hasPrefix(prefix) {
            answer.removeFirst(prefix.count)
            break
        }
        answer = answer.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines.union(
                CharacterSet(charactersIn: ":：")
            )
        )

        var labels: [String] = []
        for character in answer {
            if let label = normalizedLabel(String(character)) {
                labels.append(label)
                continue
            }
            guard character.unicodeScalars.allSatisfy(answerSeparators.contains) else {
                return false
            }
        }
        return Set(labels).count > 1
    }

    static func optionLabels(in text: String, questionType: QuestionType) -> [String] {
        guard !text.isEmpty else {
            return questionType == .choice ? ["A", "B", "C", "D"] : []
        }
        let searchRange = NSRange(text.startIndex..<text.endIndex, in: text)
        var matches: [(location: Int, label: String)] = []

        for pattern in patterns {
            guard let expression = try? NSRegularExpression(pattern: pattern) else {
                continue
            }
            for match in expression.matches(in: text, range: searchRange) {
                guard match.numberOfRanges > 1,
                      let range = Range(match.range(at: 1), in: text),
                      let label = normalizedLabel(String(text[range])) else {
                    continue
                }
                matches.append((match.range.location, label))
            }
        }

        var seen: Set<String> = []
        let labels = matches
            .sorted { $0.location < $1.location }
            .compactMap { match -> String? in
                guard seen.insert(match.label).inserted else { return nil }
                return match.label
            }

        if labels.count >= 2 {
            return labels
        }
        return questionType == .choice ? ["A", "B", "C", "D"] : []
    }

    private static func normalizedLabel(_ value: String) -> String? {
        return switch value.uppercased() {
        case "A", "Ａ": "A"
        case "B", "Ｂ": "B"
        case "C", "Ｃ": "C"
        case "D", "Ｄ": "D"
        case "E", "Ｅ": "E"
        case "F", "Ｆ": "F"
        case "G", "Ｇ": "G"
        case "H", "Ｈ": "H"
        default: nil
        }
    }
}

// MARK: - AnswerCanvas（UIViewRepresentable）

/// 答题用 PKCanvasView：Apple Pencil 绘图，手指滚动父 ScrollView。
/// 所有实例共享同一个 PKToolPicker（由 static 保证）。
struct AnswerCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    /// 全会话共用一个工具选择器，避免多个工具栏同时出现
    static let sharedToolPicker: PKToolPicker = {
        let picker = PKToolPicker()
        picker.stateAutosaveName = "PaperClip.PaperAnswerTools"
        return picker
    }()

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = UIColor.systemBackground
        canvas.isOpaque = true
        canvas.drawingPolicy = .pencilOnly   // 手指保留给父 ScrollView 滚动
        canvas.isScrollEnabled = false
        canvas.drawing = drawing
        canvas.delegate = context.coordinator

        AnswerCanvas.sharedToolPicker.addObserver(canvas)
        AnswerCanvas.sharedToolPicker.setVisible(true, forFirstResponder: canvas)

        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        // 仅在外部重置（清除）时同步（避免与 delegate 回调循环）
        if context.coordinator.suppressUpdate {
            context.coordinator.suppressUpdate = false
            return
        }
        if canvas.drawing.dataRepresentation() != drawing.dataRepresentation() {
            canvas.drawing = drawing
        }
        // 延迟显示工具选择器，确保视图已在窗口中
        if canvas.window != nil {
            AnswerCanvas.sharedToolPicker.setVisible(true, forFirstResponder: canvas)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(drawing: $drawing) }

    static func dismantleUIView(_ canvas: PKCanvasView, coordinator: Coordinator) {
        AnswerCanvas.sharedToolPicker.setVisible(false, forFirstResponder: canvas)
        AnswerCanvas.sharedToolPicker.removeObserver(canvas)
        canvas.delegate = nil
    }

    @MainActor
    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var drawing: Binding<PKDrawing>
        var suppressUpdate = false

        init(drawing: Binding<PKDrawing>) {
            self.drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            suppressUpdate = true
            drawing.wrappedValue = canvasView.drawing
        }
    }
}

// MARK: - PaperResultView（对答案 + 标记掌握）

struct PaperResultView: View {
    let cards: [MistakeCard]
    let drawings: [UUID: PKDrawing]
    let selectedAnswers: [UUID: String]
    let textAnswers: [UUID: String]
    let onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var marks: [UUID: String]  // PracticeMark raw value
    @State private var isSubmitted = false
    @State private var alert: AppAlert?

    init(
        cards: [MistakeCard],
        drawings: [UUID: PKDrawing],
        selectedAnswers: [UUID: String],
        textAnswers: [UUID: String],
        onComplete: @escaping () -> Void
    ) {
        self.cards = cards
        self.drawings = drawings
        self.selectedAnswers = selectedAnswers
        self.textAnswers = textAnswers
        self.onComplete = onComplete
        _marks = State(
            initialValue: PaperAnswerGrader.initialMarks(
                cards: cards,
                selectedAnswers: selectedAnswers,
                textAnswers: textAnswers
            )
        )
    }

    private var gotItCount: Int { marks.values.filter { $0 == PracticeMark.gotIt.rawValue }.count }
    private var notYetCount: Int { marks.values.filter { $0 == PracticeMark.notYet.rawValue }.count }
    private var unmarkedCount: Int { cards.count - gotItCount - notYetCount }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // 统计摘要
                HStack(spacing: 16) {
                    PaperScoreTile(count: gotItCount, label: "答对", color: .green, icon: "checkmark.circle.fill")
                    PaperScoreTile(count: notYetCount, label: "答错", color: .red, icon: "xmark.circle.fill")
                    PaperScoreTile(count: unmarkedCount, label: "待自评", color: .secondary, icon: "person.crop.circle.badge.questionmark")
                }
                .padding(.top, 12)

                // 同步状态
                if isSubmitted {
                    Label("已自动同步掌握状态到错题库", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline.weight(.medium))
                } else {
                    Button { syncMarks() } label: {
                        Label("同步掌握状态到错题库", systemImage: "arrow.up.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 4)
                    .disabled(marks.isEmpty)
                }

                Divider()

                // 每题对比
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    PaperResultItemView(
                        index: index + 1,
                        card: card,
                        drawing: drawings[card.id] ?? PKDrawing(),
                        selectedAnswer: selectedAnswers[card.id] ?? "",
                        textAnswer: textAnswers[card.id] ?? "",
                        mark: Binding(
                            get: { marks[card.id] ?? "" },
                            set: { marks[card.id] = $0 }
                        )
                    )
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("对答案")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") { onComplete() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .appAlert($alert)
    }

    private func syncMarks() {
        for card in cards {
            switch marks[card.id] {
            case PracticeMark.gotIt.rawValue:
                card.status = MasteryStatus.nextLevel(after: card.status).rawValue
                card.updatedAt = .now
            case PracticeMark.notYet.rawValue:
                card.status = MasteryStatus.unmastered.rawValue
                card.updatedAt = .now
            default:
                break
            }
        }
        do {
            try modelContext.save()
            isSubmitted = true
        } catch {
            alert = AppAlert(title: "无法同步掌握状态", error: error)
        }
    }
}

// MARK: - PaperResultItemView（单题对答案卡）

private struct PaperResultItemView: View {
    let index: Int
    let card: MistakeCard
    let drawing: PKDrawing
    let selectedAnswer: String
    let textAnswer: String
    @Binding var mark: String

    private var questionType: QuestionType {
        card.resolvedQuestionType
    }

    private var drawingImage: UIImage? {
        guard !drawing.strokes.isEmpty else { return nil }
        var b = drawing.bounds.insetBy(dx: -24, dy: -24)
        if b.width <= 0 || b.height <= 0 { b = CGRect(x: 0, y: 0, width: 320, height: 200) }
        return drawing.image(from: b, scale: 2.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 题头 + 标记按钮
            HStack(spacing: 8) {
                Text("第 \(index) 题")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
                Text(card.subject)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if PaperAnswerGrader.canAutomaticallyGrade(card) {
                    Label("自动批改", systemImage: "checkmark.seal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                markButton(PracticeMark.notYet.rawValue, label: "答错", color: .red, icon: "xmark.circle.fill")
                markButton(PracticeMark.gotIt.rawValue, label: "答对", color: .green, icon: "checkmark.circle.fill")
            }

            Divider()

            // 题目原题
            if !card.recognizedText.isEmpty {
                RecognitionPreviewView(question: card.recognizedText, isEmbedded: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
            }
            if let img = card.questionImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // 我的答案
            Label("我的答案", systemImage: answerSystemImage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.blue)
                .padding(.top, 4)

            switch questionType {
            case .choice, .trueFalse:
                Label(
                    selectedAnswer.isEmpty ? "未选择" : selectedAnswer,
                    systemImage: selectedAnswer.isEmpty ? "minus.circle" : "checkmark.circle.fill"
                )
                .font(.headline)
                .foregroundStyle(selectedAnswer.isEmpty ? Color.secondary : Color.accentColor)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityLabel(selectedAnswer.isEmpty ? "未选择答案" : "答案 \(selectedAnswer)")
            case .fillBlank:
                Text(textAnswer.isEmpty ? "未作答" : textAnswer)
                    .font(.body)
                    .foregroundStyle(textAnswer.isEmpty ? .tertiary : .primary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
            default:
                if let img = drawingImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator), lineWidth: 0.5))
                        .shadow(color: .black.opacity(0.04), radius: 4)
                } else {
                    Text("未作答")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                }
            }

            if !card.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Label("正确答案", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.green)
                    .padding(.top, 4)

                RecognitionPreviewView(question: card.correctAnswer, isEmbedded: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityLabel("正确答案：\(card.correctAnswer)")
            } else {
                Label("暂无正确答案，请人工判断", systemImage: "person.crop.circle.badge.questionmark")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    private var answerSystemImage: String {
        switch questionType {
        case .choice, .trueFalse: questionType.systemImage
        case .fillBlank: "keyboard"
        default: "pencil"
        }
    }

    @ViewBuilder
    private func markButton(_ value: String, label: String, color: Color, icon: String) -> some View {
        let isActive = mark == value
        Button {
            mark = isActive ? "" : value
        } label: {
            Label(label, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isActive ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isActive ? color : color.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 8)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label)\(isActive ? "（已选）" : "")")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

// 客观题和填空题使用确定性字符串比对完成本地批改。
// 主观题与没有标准答案的旧数据保留人工自评，避免未经验证的自动判分。
private enum PaperAnswerGrader {
    static func initialMarks(
        cards: [MistakeCard],
        selectedAnswers: [UUID: String],
        textAnswers: [UUID: String]
    ) -> [UUID: String] {
        var marks: [UUID: String] = [:]
        for card in cards where canAutomaticallyGrade(card) {
            let answer: String
            switch card.resolvedQuestionType {
            case .choice, .trueFalse:
                answer = selectedAnswers[card.id] ?? ""
            case .fillBlank:
                answer = textAnswers[card.id] ?? ""
            default:
                continue
            }
            marks[card.id] = isCorrect(answer, for: card)
                ? PracticeMark.gotIt.rawValue
                : PracticeMark.notYet.rawValue
        }
        return marks
    }

    static func canAutomaticallyGrade(_ card: MistakeCard) -> Bool {
        guard !card.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        return switch card.resolvedQuestionType {
        case .choice, .trueFalse, .fillBlank: true
        default: false
        }
    }

    private static func isCorrect(_ answer: String, for card: MistakeCard) -> Bool {
        switch card.resolvedQuestionType {
        case .choice:
            return normalizedChoice(answer) == normalizedChoice(card.correctAnswer)
                && !normalizedChoice(answer).isEmpty
        case .trueFalse:
            return normalizedTrueFalse(answer) == normalizedTrueFalse(card.correctAnswer)
                && !normalizedTrueFalse(answer).isEmpty
        case .fillBlank:
            return normalizedText(answer) == normalizedText(card.correctAnswer)
                && !normalizedText(answer).isEmpty
        default:
            return false
        }
    }

    private static func normalizedChoice(_ value: String) -> String {
        var text = value.uppercased()
            .replacingOccurrences(of: "Ａ", with: "A")
            .replacingOccurrences(of: "Ｂ", with: "B")
            .replacingOccurrences(of: "Ｃ", with: "C")
            .replacingOccurrences(of: "Ｄ", with: "D")
            .replacingOccurrences(of: "Ｅ", with: "E")
            .replacingOccurrences(of: "Ｆ", with: "F")
            .replacingOccurrences(of: "Ｇ", with: "G")
            .replacingOccurrences(of: "Ｈ", with: "H")
        for prefix in ["正确答案", "答案", "选项"] {
            text = text.replacingOccurrences(of: prefix, with: "")
        }
        let labels = text.filter { ("A" ... "H").contains(String($0)) }
        var seen: Set<Character> = []
        return String(labels.filter { seen.insert($0).inserted })
    }

    private static func normalizedTrueFalse(_ value: String) -> String {
        let text = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if ["正确", "对", "是", "√", "true", "t"].contains(text) { return "正确" }
        if ["错误", "错", "否", "×", "x", "false", "f"].contains(text) { return "错误" }
        return text
    }

    private static func normalizedText(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "\\(", with: "")
            .replacingOccurrences(of: "\\)", with: "")
            .replacingOccurrences(of: "；", with: ";")
            .replacingOccurrences(of: "，", with: ",")
            .replacingOccurrences(of: "。", with: "")
            .filter { !$0.isWhitespace }
            .trimmingCharacters(in: CharacterSet(charactersIn: ";,."))
    }
}

// MARK: - PaperScoreTile（分数小卡）

private struct PaperScoreTile: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title2).foregroundStyle(color)
            Text("\(count)").font(.title.bold()).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }
}
