import SwiftUI

struct PaperResultItemHeader: View {
    let index: Int
    let card: MistakeCard
    @Binding var mark: String

    var body: some View {
        HStack(spacing: 8) {
            Text("第 \(index) 题")
                .font(.headline)
                .foregroundStyle(Color.accentColor)
            Text(card.subject)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if PaperAnswerGrader.canAutomaticallyGrade(card) {
                Label("自动批改", systemImage: "checkmark.seal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Picker("作答结果", selection: $mark) {
                Text("未标记").tag("")
                Text("答错").tag(PracticeMark.notYet.rawValue)
                Text("答对").tag(PracticeMark.gotIt.rawValue)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 220)
        }
    }
}

struct PaperSubmittedAnswerSection: View {
    let questionType: QuestionType
    let selectedAnswer: String
    let textAnswer: String
    let drawingImage: UIImage?
    let isDrawingPreviewLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("我的答案", systemImage: answerSystemImage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.blue)
                .padding(.top, 4)

            PaperSubmittedAnswerContent(
                questionType: questionType,
                selectedAnswer: selectedAnswer,
                textAnswer: textAnswer,
                drawingImage: drawingImage,
                isDrawingPreviewLoading: isDrawingPreviewLoading
            )
        }
    }

    private var answerSystemImage: String {
        switch questionType {
        case .choice, .trueFalse: questionType.systemImage
        case .fillBlank: "keyboard"
        default: "pencil"
        }
    }
}

struct PaperCorrectAnswerSection: View {
    let correctAnswer: String

    var body: some View {
        if !correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Label("正确答案", systemImage: "checkmark.seal.fill")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.green)
                .padding(.top, 4)

            RecognitionPreviewView(question: correctAnswer, isEmbedded: true)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityLabel("正确答案：\(correctAnswer)")
        } else {
            Label("暂无正确答案，请人工判断", systemImage: "person.crop.circle.badge.questionmark")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }
}
