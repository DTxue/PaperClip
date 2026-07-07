import Foundation
import SwiftData

@main
struct WritingPersistenceTests {
    @MainActor
    static func main() throws {
        let schema = Schema([
            WritingPrompt.self,
            WritingDraft.self,
            WritingReview.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        expect(WritingPrompt.deletionPropertiesToFetch.count == 1)
        expect(WritingDraft.deletionPropertiesToFetch.count == 1)
        expect(WritingReview.deletionPropertiesToFetch.count == 1)

        let prompt = WritingPrompt(
            language: .chinese,
            studentGrade: "初三",
            requirementInput: "写一次成长经历",
            generatedTitle: "成长",
            generatedRequirement: "写一篇记叙文"
        )
        let draft = WritingDraft(
            promptID: prompt.id,
            language: .chinese,
            drawingData: Data([1, 2, 3])
        )
        let review = WritingReview(
            promptID: prompt.id,
            draftID: draft.id,
            language: .chinese,
            recognizedText: "作文内容",
            reviewJSONData: Data([4, 5, 6]),
            overallJudgement: "结构清楚",
            teacherComment: "继续保持",
            scoreText: "55"
        )
        let unrelatedPrompt = WritingPrompt(
            language: .chinese,
            studentGrade: "初三",
            requirementInput: "介绍一个工具",
            generatedTitle: "工具",
            generatedRequirement: "写一篇说明文"
        )
        context.insert(prompt)
        context.insert(draft)
        context.insert(review)
        context.insert(unrelatedPrompt)
        try context.save()

        try context.deleteWritingPromptCascade(promptID: prompt.id)
        try context.save()

        let remainingPrompts = try context.fetch(FetchDescriptor<WritingPrompt>())
        let remainingDrafts = try context.fetch(FetchDescriptor<WritingDraft>())
        let remainingReviews = try context.fetch(FetchDescriptor<WritingReview>())

        expect(remainingPrompts.map(\.id) == [unrelatedPrompt.id])
        expect(remainingDrafts.isEmpty)
        expect(remainingReviews.isEmpty)

        print("WritingPersistenceTests: 6 passed")
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError("Expectation failed", file: file, line: line)
        }
    }
}
