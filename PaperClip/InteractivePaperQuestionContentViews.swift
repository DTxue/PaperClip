import SwiftUI

struct PaperQuestionHeader: View {
    let index: Int
    let card: MistakeCard
    let questionType: QuestionType

    var body: some View {
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

            if !card.tagPreviewText.isEmpty {
                Text(card.tagPreviewText)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .lineLimit(1)
            }

            Spacer()
            StatusBadge(status: card.status)
        }
    }
}

struct PaperQuestionContent: View {
    let card: MistakeCard
    let maxImageHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !card.recognizedText.isEmpty {
                RecognitionPreviewView(question: card.recognizedText, isEmbedded: true)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        Color(.tertiarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .accessibilityLabel("题目内容：\(card.recognizedText)")
            }

            AsyncLocalImage(path: card.imageURL.path, normalizedCrop: card.questionCrop) { image in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: maxImageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("题目图片")
            } placeholder: {
                EmptyView()
            }
        }
    }
}
