import SwiftUI

struct VocabularyTestResultsView: View {
    let title: String
    let questions: [VocabularyGradedQuestion]
    @Binding var enlargedImage: IdentifiableImage?

    private var score: Int {
        questions.filter { $0.item?.isCorrect == true }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                Divider()
                ForEach(questions) { question in
                    VocabularyTestQuestionResultRow(
                        question: question,
                        enlargedImage: $enlargedImage
                    )
                    Divider()
                }
            }
        }
        .sheet(item: $enlargedImage) { wrapper in
            VocabularyAnswerImagePreview(image: wrapper.image) {
                enlargedImage = nil
            }
        }
    }

    private var header: some View {
        let total = questions.count
        return VStack(spacing: 8) {
            Image(systemName: score * 5 >= total * 4 ? "checkmark.seal.fill" : "checklist")
                .font(.system(size: 48))
                .foregroundStyle(score * 5 >= total * 4 ? Color.green : Color.accentColor)
            Text(title)
                .font(.title.bold())
            Text("得分 \(score) / \(total)")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 28)
    }
}

struct VocabularyTestErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ContentUnavailableView {
                Label("批改失败", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("重新批改", systemImage: "arrow.clockwise") {
                    retry()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
