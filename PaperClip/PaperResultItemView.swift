import SwiftUI
import PencilKit

// MARK: - PaperResultItemView（单题对答案卡）

struct PaperResultItemView: View {
    let index: Int
    let card: MistakeCard
    let drawing: PKDrawing
    let selectedAnswer: String
    let textAnswer: String
    @Binding var mark: String

    @State private var drawingImage: UIImage?
    @State private var isDrawingPreviewLoading = false

    var questionType: QuestionType {
        card.resolvedQuestionType
    }

    var drawingPreviewKey: String {
        guard DrawingDataSupport.hasInk(drawing) else { return "empty" }
        let bounds = drawing.bounds
        return [
            "\(drawing.strokes.count)",
            "\(Int(bounds.minX.rounded()))",
            "\(Int(bounds.minY.rounded()))",
            "\(Int(bounds.width.rounded()))",
            "\(Int(bounds.height.rounded()))"
        ].joined(separator: ":")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PaperResultItemHeader(index: index, card: card, mark: $mark)

            Divider()

            // 题目原题
            if !card.recognizedText.isEmpty {
                RecognitionPreviewView(question: card.recognizedText, isEmbedded: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
            }
            AsyncLocalImage(path: card.imageURL.path, normalizedCrop: card.questionCrop) { image in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } placeholder: {
                EmptyView()
            }

            PaperSubmittedAnswerSection(
                questionType: questionType,
                selectedAnswer: selectedAnswer,
                textAnswer: textAnswer,
                drawingImage: drawingImage,
                isDrawingPreviewLoading: isDrawingPreviewLoading
            )

            PaperCorrectAnswerSection(correctAnswer: card.correctAnswer)
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        .task(id: drawingPreviewKey) {
            await loadDrawingPreviewIfNeeded()
        }
    }

    func loadDrawingPreviewIfNeeded() async {
        guard shouldRenderDrawingPreview else {
            drawingImage = nil
            isDrawingPreviewLoading = false
            return
        }

        isDrawingPreviewLoading = true
        let image = await PaperAnswerDrawingPreviewRenderer.render(drawing)
        guard !Task.isCancelled else { return }
        drawingImage = image
        isDrawingPreviewLoading = false
    }

    var shouldRenderDrawingPreview: Bool {
        switch questionType {
        case .choice, .trueFalse, .fillBlank:
            false
        default:
            DrawingDataSupport.hasInk(drawing)
        }
    }
}
