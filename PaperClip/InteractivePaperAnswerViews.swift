import PencilKit
import SwiftUI

struct PaperObjectiveAnswerArea: View {
    let index: Int
    let questionType: QuestionType
    let options: [String]
    let isMultipleChoice: Bool
    @Binding var selectedAnswer: String

    var body: some View {
        PaperAnswerAreaSection(
            questionType == .trueFalse ? "判断答案" : "选择答案",
            systemImage: questionType.systemImage
        ) {
            if isMultipleChoice {
                PaperMultipleChoiceOptions(options: options, selectedAnswer: $selectedAnswer)
            } else {
                PaperSingleChoicePicker(
                    index: index,
                    options: options,
                    selectedAnswer: $selectedAnswer
                )
            }
        }
    }
}

struct PaperFillBlankAnswerArea: View {
    let index: Int
    @Binding var textAnswer: String

    var body: some View {
        PaperAnswerAreaSection("填写答案", systemImage: QuestionType.fillBlank.systemImage) {
            TextField("在此填写空格答案", text: $textAnswer, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .accessibilityLabel("第 \(index) 题填空答案")
        }
    }
}

struct PaperHandwritingAnswerArea: View {
    let index: Int
    @Binding var drawing: PKDrawing
    @Binding var canvasHeight: CGFloat
    @Binding var drawingReloadToken: Int

    var body: some View {
        PaperAnswerAreaSection("手写答题区", systemImage: "pencil.and.ruler") {
            PaperAnswerIconButton(systemImage: "trash", accessibilityLabel: "清除手写") {
                drawing = PKDrawing()
                drawingReloadToken &+= 1
            }

            PaperAnswerIconButton(systemImage: "arrow.down.to.line", accessibilityLabel: "扩展答题区") {
                canvasHeight += 150
            }
        } content: {
            AnswerCanvas(drawing: $drawing, reloadToken: drawingReloadToken)
                .frame(height: canvasHeight)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
                .accessibilityLabel("手写答题区，第 \(index) 题")
        }
    }
}
