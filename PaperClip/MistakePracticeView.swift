import SwiftUI
import SwiftData
import PencilKit

// MARK: - Canvas

/// 轻量 PKCanvasView 包装，供练习模式使用。
/// PKToolPicker 在 updateUIView 中延迟绑定（等待 canvas 被加入 window 后）。
struct PracticeCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let isEnabled: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .pencilOnly
        canvas.backgroundColor = UIColor.systemBackground
        canvas.isOpaque = true
        canvas.isScrollEnabled = false
        canvas.drawing = drawing
        canvas.delegate = context.coordinator
        canvas.isUserInteractionEnabled = isEnabled
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        context.coordinator.parent = self
        // 仅在外部更新（切卡）时同步 drawing，避免写入循环
        if context.coordinator.ignoreNextUpdate {
            context.coordinator.ignoreNextUpdate = false
        } else if canvas.drawing != drawing {
            canvas.drawing = drawing
        }
        canvas.isUserInteractionEnabled = isEnabled

        // 延迟绑定 PKToolPicker（需要 canvas 已附加到 window）
        if context.coordinator.toolPicker == nil,
           canvas.window != nil {
            let picker = PKToolPicker()
            picker.stateAutosaveName = "PaperClip.PracticeTools"
            picker.addObserver(canvas)
            picker.setVisible(true, forFirstResponder: canvas)
            context.coordinator.toolPicker = picker
            canvas.becomeFirstResponder()
        }
    }

    static func dismantleUIView(_ canvas: PKCanvasView, coordinator: Coordinator) {
        if let picker = coordinator.toolPicker {
            picker.setVisible(false, forFirstResponder: canvas)
            picker.removeObserver(canvas)
        }
        canvas.delegate = nil
        canvas.resignFirstResponder()
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PracticeCanvasView
        var toolPicker: PKToolPicker?
        /// 切卡后忽略下一次因外部 drawing 变化触发的 updateUIView
        var ignoreNextUpdate = false

        init(_ parent: PracticeCanvasView) { self.parent = parent }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            ignoreNextUpdate = true
            parent.drawing = canvasView.drawing
        }
    }
}

// MARK: - Practice View

/// 错题练习主视图：逐张展示错题，学生在画布上作答，然后标记"会了"或"还不会"。
/// 练习完成后进入 PracticeSummaryView，确认后将标记结果同步至错题库。
struct MistakePracticeView: View {
    let cards: [MistakeCard]
    let practiceGroupID: UUID
    let round: Int

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex = 0
    @State private var currentDrawing = PKDrawing()
    /// cardID → PracticeMark.rawValue
    @State private var marks: [UUID: String] = [:]
    /// cardID → 已保存的画布数据
    @State private var savedDrawings: [UUID: Data] = [:]
    @State private var showSummary = false
    @State private var showExitConfirm = false
    @State private var alert: AppAlert?

    private var card: MistakeCard { cards[currentIndex] }
    private var progress: Double {
        cards.isEmpty ? 0 : Double(currentIndex + 1) / Double(cards.count)
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    ContentUnavailableView(
                        "没有可练习的错题",
                        systemImage: "rectangle.stack",
                        description: Text("返回错题库后重新选择练习范围。")
                    )
                } else if showSummary {
                    PracticeSummaryView(
                        cards: cards,
                        marks: marks,
                        practiceGroupID: practiceGroupID,
                        round: round,
                        onAutoSubmit: submitMarks,
                        onClose: dismiss.callAsFunction
                    )
                    .navigationTitle("练习完成")
                    .navigationBarTitleDisplayMode(.inline)
                } else {
                    practiceBody
                        .navigationTitle(
                            round > 1
                                ? "第 \(currentIndex + 1) / \(cards.count) 题  ·  第 \(round) 轮"
                                : "第 \(currentIndex + 1) / \(cards.count) 题"
                        )
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("结束") { showExitConfirm = true }
                                    .foregroundStyle(.secondary)
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    goBack()
                                } label: {
                                    Image(systemName: "chevron.left")
                                }
                                .disabled(currentIndex == 0)
                            }
                        }
                        .confirmationDialog("结束本次练习？", isPresented: $showExitConfirm) {
                            Button("结束练习", role: .destructive) { dismiss() }
                            Button("取消", role: .cancel) {}
                        } message: {
                            Text("已标记内容将不会同步到错题库。")
                        }
                }
            }
        }
        .appAlert($alert)
    }

    // MARK: Practice Layout

    @ViewBuilder
    private var practiceBody: some View {
        VStack(spacing: 0) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.accentColor)
                .animation(.spring(duration: 0.3), value: currentIndex)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            markCountRow

            GeometryReader { geo in
                VStack(spacing: 0) {
                    // 上半：错题图片
                    ScrollView {
                        cardImageView
                            .padding(16)
                    }
                    .frame(height: geo.size.height * 0.46)
                    .background(Color.white)
                    .overlay(alignment: .topLeading) { subjectTag }

                    Divider()

                    // 下半：答题画布
                    ZStack {
                        Color(.systemBackground)
                        PracticeCanvasView(drawing: $currentDrawing, isEnabled: true)
                    }
                    .frame(height: geo.size.height * 0.54)
                    .overlay(alignment: .topLeading) {
                        Label("答题区", systemImage: "pencil")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(8)
                            .allowsHitTesting(false)
                    }
                }
            }

            Divider()
            markButtonRow
        }
    }

    // MARK: Sub-views

    private var markCountRow: some View {
        let gotCount = marks.values.filter { $0 == PracticeMark.gotIt.rawValue }.count
        let notCount = marks.values.filter { $0 == PracticeMark.notYet.rawValue }.count
        return HStack(spacing: 14) {
            Label("\(gotCount) 会了", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Label("\(notCount) 不会", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
            Spacer()
            Text("\(cards.count - gotCount - notCount) 待标记")
                .foregroundStyle(.tertiary)
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var cardImageView: some View {
        CardImage(url: card.imageURL, maxPixelSize: 1200)
            .frame(maxWidth: .infinity)
    }

    private var subjectTag: some View {
        HStack(spacing: 6) {
            Text(card.subject)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor, in: Capsule())
            if !card.tags.isEmpty {
                Text(card.tags.prefix(2).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .allowsHitTesting(false)
    }

    private var markButtonRow: some View {
        HStack(spacing: 24) {
            Spacer()
            // 跳过
            Button {
                applyMark(nil)
            } label: {
                Text("跳过")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // 还不会
            Button {
                applyMark(.notYet)
            } label: {
                Label("还不会", systemImage: "xmark.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.red)

            // 会了
            Button {
                applyMark(.gotIt)
            } label: {
                Label("会了", systemImage: "checkmark.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.green)

            Spacer()
        }
        .padding(.vertical, 16)
    }

    // MARK: Actions

    private func applyMark(_ practiceMark: PracticeMark?) {
        // 保存当前画布
        savedDrawings[card.id] = currentDrawing.dataRepresentation()
        // 记录标记
        marks[card.id] = practiceMark?.rawValue ?? ""
        // 持久化到 SwiftData
        guard upsertPracticeLayer(
            cardID: card.id,
            mark: practiceMark?.rawValue ?? ""
        ) else { return }

        if currentIndex + 1 < cards.count {
            loadCard(at: currentIndex + 1)
        } else {
            showSummary = true
        }
    }

    private func goBack() {
        guard currentIndex > 0 else { return }
        savedDrawings[card.id] = currentDrawing.dataRepresentation()
        loadCard(at: currentIndex - 1)
    }

    private func loadCard(at index: Int) {
        currentIndex = index
        let targetCard = cards[index]
        if let data = savedDrawings[targetCard.id],
           let drawing = try? PKDrawing(data: data) {
            currentDrawing = drawing
        } else {
            currentDrawing = PKDrawing()
        }
    }

    /// 新增或更新 (cardID, practiceGroupID, round) 对应的画布层
    private func upsertPracticeLayer(cardID: UUID, mark: String) -> Bool {
        let groupID = practiceGroupID
        let r = round
        let descriptor = FetchDescriptor<MistakePracticeLayer>(
            predicate: #Predicate {
                $0.cardID == cardID &&
                $0.practiceGroupID == groupID &&
                $0.round == r
            }
        )
        do {
            if let existing = try modelContext.fetch(descriptor).first {
                existing.drawingData = savedDrawings[cardID] ?? Data()
                existing.mark = mark
            } else {
                let layer = MistakePracticeLayer(
                    cardID: cardID,
                    practiceGroupID: groupID,
                    round: r,
                    drawingData: savedDrawings[cardID] ?? Data(),
                    mark: mark
                )
                modelContext.insert(layer)
            }
            try modelContext.save()
            return true
        } catch {
            alert = AppAlert(title: "无法保存练习记录", error: error)
            return false
        }
    }

    /// 将标记结果同步到错题库（不关闭界面，供 Summary 自动调用）
    func submitMarks() {
        for c in cards {
            switch marks[c.id] {
            case PracticeMark.gotIt.rawValue:
                c.status = MasteryStatus.nextLevel(after: c.status).rawValue
                c.updatedAt = .now
            case PracticeMark.notYet.rawValue:
                c.status = MasteryStatus.unmastered.rawValue
                c.updatedAt = .now
            default:
                break
            }
        }
        do {
            try modelContext.save()
        } catch {
            alert = AppAlert(title: "无法同步练习结果", error: error)
        }
    }
}

// MARK: - Summary View

struct PracticeSummaryView: View {
    let cards: [MistakeCard]
    let marks: [UUID: String]
    let practiceGroupID: UUID
    let round: Int
    /// 进入 Summary 后立即自动调用，同步标记到错题库
    let onAutoSubmit: () -> Void
    let onClose: () -> Void

    @State private var showRetry = false
    @State private var isSubmitted = false

    private var gotItCards: [MistakeCard] {
        cards.filter { marks[$0.id] == PracticeMark.gotIt.rawValue }
    }
    private var notYetCards: [MistakeCard] {
        cards.filter { marks[$0.id] == PracticeMark.notYet.rawValue }
    }
    private var skippedCards: [MistakeCard] {
        cards.filter { (marks[$0.id] ?? "").isEmpty }
    }
    private var accuracy: Int {
        cards.isEmpty ? 0 : Int(Double(gotItCards.count) / Double(cards.count) * 100)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // 成绩徽章
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(accuracyColor.opacity(0.12))
                            .frame(width: 110, height: 110)
                        Text("\(accuracy)%")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(accuracyColor)
                    }
                    Text("第 \(round) 轮练习完成")
                        .font(.title2.bold())
                    Text("\(cards.count) 题 · \(gotItCards.count) 题会了 · \(notYetCards.count) 题不会")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                // 三格分数
                HStack(spacing: 16) {
                    ScoreTile(count: gotItCards.count, label: "会了", color: .green, icon: "checkmark.circle.fill")
                    ScoreTile(count: notYetCards.count, label: "不会", color: .red, icon: "xmark.circle.fill")
                    ScoreTile(count: skippedCards.count, label: "跳过", color: .secondary, icon: "forward.fill")
                }

                // 不会的题目列表
                if !notYetCards.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("还不会的 \(notYetCards.count) 道题", systemImage: "xmark.circle")
                            .font(.headline)
                            .foregroundStyle(.red)
                        ForEach(notYetCards) { c in
                            HStack(spacing: 12) {
                                CardImage(url: c.imageURL, maxPixelSize: 200)
                                    .frame(width: 72, height: 52)
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(c.subject)
                                        .font(.subheadline.weight(.medium))
                                    if !c.tags.isEmpty {
                                        Text(c.tags.prefix(3).joined(separator: " · "))
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                }
                                Spacer()
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                            .padding(12)
                            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                // 已自动同步标记
                Label("已自动同步到错题库", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline.weight(.medium))

                // 操作按钮
                VStack(spacing: 14) {
                    if !notYetCards.isEmpty {
                        Button {
                            showRetry = true
                        } label: {
                            Label("再练一轮不会的 \(notYetCards.count) 道题", systemImage: "arrow.clockwise")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }

                    Button("关闭", action: onClose)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 28)
        }
        .task {
            // 进入 Summary 时立即同步，无需手动点击"确认提交"
            guard !isSubmitted else { return }
            isSubmitted = true
            onAutoSubmit()
        }
        .fullScreenCover(isPresented: $showRetry) {
            MistakePracticeView(
                cards: notYetCards,
                practiceGroupID: practiceGroupID,
                round: round + 1
            )
        }
    }

    private var accuracyColor: Color {
        accuracy >= 80 ? .green : accuracy >= 50 ? .orange : .red
    }
}

// MARK: - Helpers

private struct ScoreTile: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text("\(count)")
                .font(.title.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }
}
