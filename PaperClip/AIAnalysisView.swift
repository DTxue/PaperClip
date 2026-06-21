import SwiftUI

struct AIAnalysisRequest: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct AIAnalysisView: View {
    @Environment(\.dismiss) private var dismiss

    let image: UIImage

    @State private var phase: Phase = .recognizing
    @State private var recognition: AIQuestionRecognition?
    @State private var confirmedQuestion = ""
    @State private var solution: AIQuestionSolution?
    @State private var selectedModel: AIAnswerModel = .doubao
    @State private var failureMessage = ""
    @State private var failedOperation: Operation = .recognition
    @State private var isEditingQuestion = false

    private enum Phase {
        case recognizing
        case review
        case solving
        case result
        case failure
    }

    private enum Operation {
        case recognition
        case solution
    }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .recognizing:
                    recognizingView
                case .review, .solving, .result:
                    splitView
                case .failure:
                    failureView
                }
            }
            .navigationTitle(phase == .recognizing ? "识别题目" : "AI 解析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .task {
            guard recognition == nil else { return }
            await recognize()
        }
        .sheet(isPresented: $isEditingQuestion) {
            NavigationStack {
                Form {
                    Section {
                        TextEditor(text: $confirmedQuestion)
                            .font(.body)
                            .frame(minHeight: 300)
                    } header: {
                        Text("题目文本")
                    } footer: {
                        Text("公式请保留 LaTeX 标记，例如 $a^2$。")
                    }
                }
                .navigationTitle("编辑识别内容")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            if let recognition {
                                confirmedQuestion = recognition.recognizedQuestion
                            }
                            isEditingQuestion = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") { isEditingQuestion = false }
                            .disabled(
                                confirmedQuestion
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                    .isEmpty
                            )
                    }
                }
            }
        }
        .presentationSizing(.page)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    // MARK: - Full-screen recognizing progress

    private var recognizingView: some View {
        VStack(spacing: 20) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("待识别的题目图片")

            ProgressView("豆包正在识别题目…")
                .controlSize(.large)

            Text("识别完成后，请先核对题目内容。")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("超过 90 秒会自动停止。")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Button("取消", role: .cancel) { dismiss() }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Two-column split layout

    private var splitView: some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.vertical, 12)
                .accessibilityLabel("已识别的题目图片")

            Divider()

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 0) {
                    leftPanel
                        .frame(minWidth: 360)
                    Divider()
                    rightPanel
                        .frame(minWidth: 360)
                }

                VStack(spacing: 0) {
                    leftPanel
                    Divider()
                    rightPanel
                        .frame(minHeight: 420)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // Left: recognition content (always visible in review/solving/result)
    @ViewBuilder
    private var leftPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                if let recognition {
                    HStack {
                        Label(recognition.subject, systemImage: "book.closed")
                        Spacer()
                        Label(recognition.questionType, systemImage: "square.grid.2x2")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    if !recognition.knowledgePoints.isEmpty {
                        KnowledgeTagLayout(spacing: 8) {
                            ForEach(
                                Array(recognition.knowledgePoints.enumerated()),
                                id: \.offset
                            ) { index, point in
                                KnowledgeTag(
                                    title: point,
                                    color: KnowledgeTag.palette[
                                        index % KnowledgeTag.palette.count
                                    ]
                                )
                            }
                        }
                    }

                    RecognitionPreviewView(question: confirmedQuestion)

                    // 编辑 / 重识别按钮，与上方识别结果保持紧凑间距
                    HStack {
                        Button {
                            isEditingQuestion = true
                        } label: {
                            Label("编辑识别内容", systemImage: "pencil")
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button {
                            Task { await recognize() }
                        } label: {
                            Label("重新识别", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                    }

                    // 选择解析模型，与上方缩小间距
                    AnalysisSection(title: "选择解析模型", systemImage: "brain") {
                        VStack(spacing: 10) {
                            modelButton(.doubao, isEnabled: true)
                            modelButton(.deepSeek, isEnabled: AIService.isDeepSeekConfigured)
                        }
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
    }

    // Right: solving progress / result / placeholder
    @ViewBuilder
    private var rightPanel: some View {
        Group {
            switch phase {
            case .review:
                ContentUnavailableView(
                    "尚未解析",
                    systemImage: "text.bubble",
                    description: Text("在左侧选择解析模型后，解析结果将在此处显示。")
                )
            case .solving:
                VStack(spacing: 16) {
                    ProgressView("\(selectedModel.shortTitle)正在解析题目…")
                        .controlSize(.large)
                    Text("正在生成思路、步骤、答案和易错点。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .result:
                if let recognition, let solution {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Label(
                                "由 \(selectedModel.title) 完成解析",
                                systemImage: selectedModel.systemImage
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                            AnalysisDocumentView(
                                analysis: AIQuestionAnalysis(
                                    recognition: recognition,
                                    confirmedQuestion: confirmedQuestion,
                                    solution: solution
                                )
                            )

                            Button {
                                phase = .review
                            } label: {
                                Label("更换模型重新解析", systemImage: "arrow.triangle.2.circlepath")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    }
                }
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func modelButton(
        _ model: AIAnswerModel,
        isEnabled: Bool
    ) -> some View {
        Button {
            selectedModel = model
            Task { await solve(using: model) }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: model.systemImage)
                    .font(.title3)
                    .foregroundStyle(model == .doubao ? .blue : .purple)
                    .frame(width: 34, height: 34)
                    .background(
                        (model == .doubao ? Color.blue : Color.purple).opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 9)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(model.title)
                        .font(.headline)
                    Text(isEnabled ? model.summary : "需要先在设置中配置推理接入点")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
        .accessibilityHint("确认识别内容无误后，使用该模型解析")
    }

    private var failureView: some View {
        ContentUnavailableView {
            Label("操作失败", systemImage: "exclamationmark.triangle")
        } description: {
            Text(failureMessage)
        } actions: {
            Button("重试") {
                Task {
                    switch failedOperation {
                    case .recognition: await recognize()
                    case .solution: await solve(using: selectedModel)
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            if recognition != nil {
                Button("返回识别结果") { phase = .review }
            }
        }
    }

    @MainActor
    private func recognize() async {
        phase = .recognizing
        failedOperation = .recognition
        do {
            let value = try await AIService.recognize(image: image)
            try Task.checkCancellation()
            recognition = value
            confirmedQuestion = value.recognizedQuestion
            solution = nil
            phase = .review
        } catch is CancellationError {
            return
        } catch {
            failureMessage = error.localizedDescription
            phase = .failure
        }
    }

    @MainActor
    private func solve(using model: AIAnswerModel) async {
        guard let recognition else { return }
        phase = .solving
        failedOperation = .solution
        selectedModel = model
        do {
            let value = try await AIService.solve(
                question: confirmedQuestion,
                recognition: recognition,
                using: model
            )
            try Task.checkCancellation()
            solution = value
            phase = .result
        } catch is CancellationError {
            return
        } catch {
            failureMessage = error.localizedDescription
            phase = .failure
        }
    }
}

// SwiftUI 尚无原生自动换行的水平标签容器。这里仅负责知识点标签换行；
// 子视图仍是原生 Text，保留 Dynamic Type、VoiceOver、深色模式和系统手势。
struct KnowledgeTagLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widestRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth > 0, rowWidth + spacing + size.width > maxWidth {
                widestRow = max(widestRow, rowWidth)
                totalHeight += rowHeight + spacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth += (rowWidth == 0 ? 0 : spacing) + size.width
                rowHeight = max(rowHeight, size.height)
            }
        }

        widestRow = max(widestRow, rowWidth)
        totalHeight += rowHeight
        return CGSize(width: min(widestRow, maxWidth), height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

private struct KnowledgeTag: View {
    static let palette: [Color] = [
        .blue, .purple, .orange, .green, .pink, .indigo, .teal
    ]

    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(color.opacity(0.13), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(color.opacity(0.28), lineWidth: 1)
            }
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityLabel("知识点：\(title)")
    }
}

private struct AnalysisSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.title3.bold())
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
    }
}
