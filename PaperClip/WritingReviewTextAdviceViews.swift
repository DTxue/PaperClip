import SwiftUI

struct WritingReviewProblemSection: View {
    let problems: [AIWritingReviewResult.Problem]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("主要问题")
                .font(.headline)
            ForEach(problems) { item in
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.problem)
                        .font(.subheadline.weight(.semibold))
                    Text(item.evidenceFromEssay)
                    Text(item.whyItWeakensEssay)
                        .foregroundStyle(.secondary)
                    Text(item.howToImprove)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

struct WritingReviewIdeaSection: View {
    let item: AIWritingReviewResult.IdeaUpgrade

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("立意提升")
                .font(.headline)
            WritingReviewTextBlock(title: "当前立意", text: item.currentIdea)
            WritingReviewTextBlock(title: "提升方向", text: item.betterDirection)
            WritingReviewTextBlock(title: "升级主题句", text: item.suggestedThemeSentence)
        }
    }
}

struct WritingReviewSampleSection: View {
    let item: AIWritingReviewResult.SampleUpgrade

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("局部示范修改")
                .font(.headline)
            WritingReviewTextBlock(title: "原问题", text: item.originalProblem)
            WritingReviewTextBlock(title: "示范修改", text: item.improvedExample)
            WritingReviewTextBlock(title: "为什么更好", text: item.whyBetter)
        }
    }
}

struct WritingReviewTextBlock: View {
    let title: String
    let text: String

    var body: some View {
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                Text(text)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
