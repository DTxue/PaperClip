import SwiftUI
import SwiftData

struct InteractivePaperView: View {
    let cards: [MistakeCard]
    let subject: String?

    @Environment(\.dismiss) private var dismiss

    @State private var answers = InteractivePaperAnswerState()
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
                        ForEach(cards.indices, id: \.self) { index in
                            let card = cards[index]
                            PaperQuestionItemView(
                                index: index + 1,
                                card: card,
                                drawing: $answers.drawing(for: card.id),
                                selectedAnswer: $answers.selectedAnswer(for: card.id),
                                textAnswer: $answers.textAnswer(for: card.id)
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
                    drawings: answers.drawings,
                    selectedAnswers: answers.selectedAnswers,
                    textAnswers: answers.textAnswers,
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
