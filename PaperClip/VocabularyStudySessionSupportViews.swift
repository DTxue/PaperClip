import SwiftUI

struct VocabularyStudySessionItemRow: View {
    let item: VocabularyStudySessionItem
    let showsRecognizedText: Bool

    private var isSuspectedPunctuation: Bool {
        item.comment.hasPrefix(VocabularyGradingPolicy.suspectedPunctuationCommentPrefix)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                isSuspectedPunctuation ? "疑似标点" : (item.isCorrect ? "正确" : "错误"),
                systemImage: isSuspectedPunctuation
                    ? "questionmark.circle.fill"
                    : (item.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSuspectedPunctuation ? Color.orange : (item.isCorrect ? Color.green : Color.red))

            Text(item.prompt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(item.expectedAnswer)
                .font(.body.weight(.semibold))

            if showsRecognizedText, let recognizedText {
                LabeledContent(item.isCorrect ? "识别结果" : "错误内容") {
                    Text(recognizedText)
                        .multilineTextAlignment(.trailing)
                }
            }
            if !item.comment.isEmpty, item.comment != "正确" {
                Text(item.comment)
                    .font(.subheadline)
                    .foregroundStyle(isSuspectedPunctuation ? Color.orange : (item.isCorrect ? Color.secondary : Color.red))
            }
        }
        .padding(.vertical, 6)
    }

    private var recognizedText: String? {
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
