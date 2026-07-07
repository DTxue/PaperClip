import SwiftUI
import PencilKit

struct PaperQuestionItemView: View {
    let index: Int
    let card: MistakeCard
    @Binding var drawing: PKDrawing
    @Binding var selectedAnswer: String
    @Binding var textAnswer: String

    @State var canvasHeight: CGFloat
    @State var drawingReloadToken = 0

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

    var questionType: QuestionType {
        card.resolvedQuestionType
    }

    var choiceOptionLabels: [String] {
        PaperChoiceParser.optionLabels(
            in: card.recognizedText,
            questionType: questionType
        )
    }

    var objectiveOptions: [String] {
        switch questionType {
        case .choice: choiceOptionLabels
        case .trueFalse: ["正确", "错误"]
        default: []
        }
    }

    var isMultipleChoice: Bool {
        guard questionType == .choice else { return false }
        return PaperChoiceParser.isMultipleChoice(
            questionText: card.recognizedText,
            correctAnswer: card.correctAnswer
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PaperQuestionHeader(index: index, card: card, questionType: questionType)

            Divider()

            PaperQuestionContent(card: card, maxImageHeight: questionImageMaxHeight)

            answerArea
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
    }

}
