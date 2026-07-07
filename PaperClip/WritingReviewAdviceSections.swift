import SwiftUI

extension WritingReviewDetailView {
    @ViewBuilder
    func problemSection(_ problems: [AIWritingReviewResult.Problem]) -> some View {
        if !problems.isEmpty {
            WritingReviewProblemSection(problems: problems)
        }
    }

    @ViewBuilder
    func ideaSection(_ item: AIWritingReviewResult.IdeaUpgrade) -> some View {
        if !item.currentIdea.isEmpty || !item.betterDirection.isEmpty || !item.suggestedThemeSentence.isEmpty {
            WritingReviewIdeaSection(item: item)
        }
    }

    @ViewBuilder
    func contentSection(_ items: [AIWritingReviewResult.ContentAdvice]) -> some View {
        if !items.isEmpty {
            adviceCards(title: "内容与材料") {
                ForEach(items) { item in
                    WritingReviewContentAdviceRow(item: item)
                }
            }
        }
    }

    @ViewBuilder
    func structureSection(_ items: [AIWritingReviewResult.StructureAdvice]) -> some View {
        if !items.isEmpty {
            adviceCards(title: "结构优化") {
                ForEach(items) { item in
                    WritingReviewStructureAdviceRow(item: item)
                }
            }
        }
    }

    @ViewBuilder
    func languageSection(_ items: [AIWritingReviewResult.LanguageUpgrade]) -> some View {
        if !items.isEmpty {
            adviceCards(title: "语言升级") {
                ForEach(items) { item in
                    WritingReviewLanguageAdviceRow(item: item)
                }
            }
        }
    }

    @ViewBuilder
    func paragraphSection(_ items: [AIWritingReviewResult.ParagraphAdvice]) -> some View {
        if !items.isEmpty {
            adviceCards(title: "分段建议") {
                ForEach(items) { item in
                    WritingReviewParagraphAdviceRow(item: item)
                }
            }
        }
    }

    @ViewBuilder
    func sampleSection(_ item: AIWritingReviewResult.SampleUpgrade?) -> some View {
        if let item, !item.originalProblem.isEmpty || !item.improvedExample.isEmpty || !item.whyBetter.isEmpty {
            WritingReviewSampleSection(item: item)
        }
    }
}
