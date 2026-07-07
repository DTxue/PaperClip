import SwiftUI
import PencilKit

extension PaperQuestionItemView {
    var questionImageMaxHeight: CGFloat {
        switch questionType {
        case .reading, .composition: 280
        case .calculation, .proof: 240
        default: 200
        }
    }

    @ViewBuilder
    var answerArea: some View {
        switch questionType {
        case .choice, .trueFalse:
            PaperObjectiveAnswerArea(
                index: index,
                questionType: questionType,
                options: objectiveOptions,
                isMultipleChoice: isMultipleChoice,
                selectedAnswer: $selectedAnswer
            )
        case .fillBlank:
            PaperFillBlankAnswerArea(index: index, textAnswer: $textAnswer)
        default:
            PaperHandwritingAnswerArea(
                index: index,
                drawing: $drawing,
                canvasHeight: $canvasHeight,
                drawingReloadToken: $drawingReloadToken
            )
        }
    }

    static func initialCanvasHeight(for type: QuestionType) -> CGFloat {
        switch type {
        case .reading, .composition: 280
        case .calculation, .proof: 220
        default: 180
        }
    }
}
