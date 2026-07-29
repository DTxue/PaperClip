import SwiftUI

struct VocabularyTestQuestionResultRow: View {
    let question: VocabularyGradedQuestion
    let handwritingTestKind: VocabularyHandwritingTestKind
    @Binding var enlargedImage: IdentifiableImage?

    private var item: VocabularyGradingItem? {
        question.item
    }

    private var isCorrect: Bool {
        item?.isCorrect == true
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            resultText
            answerImage
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var resultText: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Label(
                    isCorrect ? "正确" : "错误",
                    systemImage: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isCorrect ? Color.green : Color.red)

                Spacer()

                Text("第 \(question.globalIndex + 1) 题")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            switch handwritingTestKind {
            case .spelling:
                Text(question.card.definition)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(question.card.term)
                    .font(.body.weight(.semibold))
            case .englishDefinition:
                Text(question.card.term)
                    .font(.body.weight(.semibold))
                Text("参考释义：\(question.card.englishDefinition)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let comment = item?.comment, !comment.isEmpty, comment != "正确" {
                Text(comment)
                    .font(.body)
                    .foregroundStyle(.red)
            }

            if (handwritingTestKind == .englishDefinition || item?.isCorrect == false),
               let recognized = item?.recognizedText,
               !recognized.isEmpty {
                Text("\(handwritingTestKind == .englishDefinition ? "识别结果" : "AI 识别")：\(recognized)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var answerImage: some View {
        if let image = question.image {
            VocabularyAnswerThumbnail(image: image) {
                enlargedImage = IdentifiableImage(image)
            }
        } else {
            Text("未作答")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(width: 180, height: 60)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}
