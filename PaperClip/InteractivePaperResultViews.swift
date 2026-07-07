import SwiftUI
import SwiftData
import PencilKit

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

    var body: some View {
        PaperResultContentView(
            cards: cards,
            drawings: drawings,
            selectedAnswers: selectedAnswers,
            textAnswers: textAnswers,
            isSubmitted: isSubmitted,
            onSync: syncMarks,
            marks: $marks
        )
        .background(Color(.systemGroupedBackground))
        .navigationTitle("对答案")
        .navigationBarTitleDisplayMode(.inline)
        .prominentActionToolbar(
            "完成",
            placement: .confirmationAction,
            action: onComplete
        )
        .appAlert($alert)
    }

    private func syncMarks() {
        do {
            try PaperResultMasterySync.sync(cards: cards, marks: marks, in: modelContext)
            isSubmitted = true
        } catch {
            alert = AppAlert(title: "无法同步掌握状态", error: error)
        }
    }
}
