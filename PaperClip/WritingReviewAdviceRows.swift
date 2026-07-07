import SwiftUI

struct WritingReviewContentAdviceRow: View {
    let item: AIWritingReviewResult.ContentAdvice

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(item.keepOrChange)
                .font(.subheadline.weight(.semibold))
            Text(item.sourceContent)
            Text(item.reason)
                .foregroundStyle(.secondary)
            Text(item.revisionAdvice)
        }
    }
}

struct WritingReviewStructureAdviceRow: View {
    let item: AIWritingReviewResult.StructureAdvice

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(item.part)
                .font(.subheadline.weight(.semibold))
            Text(item.problem)
            Text(item.revisionAdvice)
                .foregroundStyle(.secondary)
        }
    }
}

struct WritingReviewLanguageAdviceRow: View {
    let item: AIWritingReviewResult.LanguageUpgrade

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(item.originalExpression)
                .font(.subheadline.weight(.semibold))
            Text(item.problem)
            if !item.betterWords.isEmpty {
                Text("可替换：\(item.betterWordsText)")
            }
            Text(item.betterSentence)
            Text(item.whyBetter)
                .foregroundStyle(.secondary)
        }
    }
}

struct WritingReviewParagraphAdviceRow: View {
    let item: AIWritingReviewResult.ParagraphAdvice

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(item.paragraph)
                .font(.subheadline.weight(.semibold))
            Text(item.comment)
            Text(item.revisionAdvice)
                .foregroundStyle(.secondary)
        }
    }
}
