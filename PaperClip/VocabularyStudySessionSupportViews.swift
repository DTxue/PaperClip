import SwiftUI

struct VocabularyStudySessionItemRow: View {
    let item: VocabularyStudySessionItem
    let showsRecognizedError: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                item.isCorrect ? "正确" : "错误",
                systemImage: item.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(item.isCorrect ? Color.green : Color.red)

            Text(item.prompt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(item.expectedAnswer)
                .font(.body.weight(.semibold))

            if showsRecognizedError, let errorText {
                LabeledContent("错误内容") {
                    Text(errorText)
                        .multilineTextAlignment(.trailing)
                }
            }
            if !item.comment.isEmpty, item.comment != "正确" {
                Text(item.comment)
                    .font(.subheadline)
                    .foregroundStyle(item.isCorrect ? Color.secondary : Color.red)
            }
        }
        .padding(.vertical, 6)
    }

    private var errorText: String? {
        let recognized = item.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        return recognized.isEmpty ? nil : recognized
    }
}

struct VocabularyMetricTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title.bold())
                .monospacedDigit()
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(.quaternary) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label)：\(value)")
    }
}
