import SwiftUI

struct PaperSubmittedAnswerContent: View {
    let questionType: QuestionType
    let selectedAnswer: String
    let textAnswer: String
    let drawingImage: UIImage?
    let isDrawingPreviewLoading: Bool

    var body: some View {
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
            PaperDrawingAnswerPreview(
                drawingImage: drawingImage,
                isLoading: isDrawingPreviewLoading
            )
        }
    }
}

struct PaperDrawingAnswerPreview: View {
    let drawingImage: UIImage?
    let isLoading: Bool

    var body: some View {
        if let img = drawingImage {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.04), radius: 4)
        } else if isLoading {
            ProgressView("正在生成手写预览")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        } else {
            Text("未作答")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        }
    }
}
