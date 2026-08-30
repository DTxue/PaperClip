import Foundation

@discardableResult
func expect(_ condition: @autoclosure () -> Bool, _ message: String) -> Bool {
    guard condition() else {
        fatalError(message)
    }
    return true
}

func makePrompt(
    id: UUID = UUID(),
    title: String,
    requirement: String,
    input: String = ""
) -> WritingPromptRowData {
    WritingPromptRowData(
        prompt: WritingPrompt(
            id: id,
            language: .chinese,
            studentGrade: "初三",
            requirementInput: input,
            generatedTitle: title,
            generatedRequirement: requirement
        )
    )
}

func makeDraft(promptID: UUID, date: Date) -> WritingDraftRowData {
    WritingDraftRowData(
        draft: WritingDraft(
            promptID: promptID,
            language: .chinese,
            updatedAt: date
        )
    )
}

func makeReview(promptID: UUID, score: String, date: Date) -> WritingReviewRowData {
    WritingReviewRowData(
        review: WritingReview(
            promptID: promptID,
            draftID: UUID(),
            language: .chinese,
            recognizedText: "",
            reviewJSONData: Data(),
            overallJudgement: "",
            teacherComment: "",
            scoreText: score,
            createdAt: date
        )
    )
}

@main
struct WritingHomeSnapshotTests {
    static func main() {
        testWhitespaceSearchDoesNotFilterPrompts()
        testMetadataIsLimitedToVisiblePrompts()
        testLatestMetadataDoesNotDependOnInputOrder()
        testRecentMetadataFetchPlan()
        testGenerationDraftTrimsRequirement()
        testOnlyChineseWritingIsAvailable()
        testOnlyChineseWritingPromptSettingsAreAvailable()
        testLegacyEnglishWritingLanguageRemainsDecodable()
        testDeletionSelectionIgnoresInvalidOffsets()
        print("WritingHomeSnapshotTests: 13 passed")
    }

    private static func testWhitespaceSearchDoesNotFilterPrompts() {
        let prompt = makePrompt(title: "记叙文训练", requirement: "写一次成长经历")
        let snapshot = WritingHomeSnapshot(
            prompts: [prompt],
            drafts: [],
            reviews: [],
            searchText: "   "
        )

        expect(snapshot.visiblePrompts.map(\.id) == [prompt.id], "whitespace search should keep all prompts")
    }

    private static func testMetadataIsLimitedToVisiblePrompts() {
        let visiblePrompt = makePrompt(title: "说明文", requirement: "介绍一个工具")
        let hiddenPrompt = makePrompt(title: "议论文", requirement: "谈学习习惯")
        let visibleDraft = makeDraft(promptID: visiblePrompt.id, date: Date(timeIntervalSince1970: 20))
        let hiddenDraft = makeDraft(promptID: hiddenPrompt.id, date: Date(timeIntervalSince1970: 30))
        let visibleReview = makeReview(promptID: visiblePrompt.id, score: "55", date: Date(timeIntervalSince1970: 20))
        let hiddenReview = makeReview(promptID: hiddenPrompt.id, score: "50", date: Date(timeIntervalSince1970: 30))

        let snapshot = WritingHomeSnapshot(
            prompts: [visiblePrompt, hiddenPrompt],
            drafts: [hiddenDraft, visibleDraft],
            reviews: [hiddenReview, visibleReview],
            searchText: "工具"
        )

        expect(snapshot.visiblePrompts.map(\.id) == [visiblePrompt.id], "search should keep matching prompt only")
        expect(snapshot.latestDraftByPromptID[visiblePrompt.id]?.id == visibleDraft.id, "visible prompt should keep draft metadata")
        expect(snapshot.latestDraftByPromptID[hiddenPrompt.id] == nil, "hidden prompt draft metadata should be skipped")
        expect(snapshot.latestReviewByPromptID[visiblePrompt.id]?.id == visibleReview.id, "visible prompt should keep review metadata")
        expect(snapshot.latestReviewByPromptID[hiddenPrompt.id] == nil, "hidden prompt review metadata should be skipped")
        expect(visiblePrompt.matchesSearch("说明文"), "prompt search should match title")
        expect(visiblePrompt.matchesSearch("工具"), "prompt search should match requirement")
        expect(!visiblePrompt.matchesSearch("议论文"), "prompt search should reject unrelated text")
    }

    private static func testLatestMetadataDoesNotDependOnInputOrder() {
        let prompt = makePrompt(title: "读后感", requirement: "写阅读感受")
        let oldDraft = makeDraft(promptID: prompt.id, date: Date(timeIntervalSince1970: 10))
        let newDraft = makeDraft(promptID: prompt.id, date: Date(timeIntervalSince1970: 30))
        let oldReview = makeReview(promptID: prompt.id, score: "50", date: Date(timeIntervalSince1970: 20))
        let newReview = makeReview(promptID: prompt.id, score: "56", date: Date(timeIntervalSince1970: 40))

        let snapshot = WritingHomeSnapshot(
            prompts: [prompt],
            drafts: [oldDraft, newDraft],
            reviews: [oldReview, newReview],
            searchText: ""
        )

        expect(snapshot.latestDraftByPromptID[prompt.id]?.id == newDraft.id, "snapshot should choose newest draft")
        expect(snapshot.latestReviewByPromptID[prompt.id]?.id == newReview.id, "snapshot should choose newest review")
    }

    private static func testRecentMetadataFetchPlan() {
        expect(WritingRecentMetadataFetchPlan.limit(promptCount: 0) == 0, "empty prompt list should skip metadata fetches")
        expect(WritingRecentMetadataFetchPlan.limit(promptCount: 1) == 200, "small prompt lists should keep the metadata floor")
        expect(WritingRecentMetadataFetchPlan.limit(promptCount: 800) == 1_000, "large prompt lists should cap metadata fetches")
    }

    private static func testGenerationDraftTrimsRequirement() {
        var draft = WritingPromptGenerationDraft(
            language: .chinese,
            studentGrade: "初二",
            requirementInput: "   "
        )
        expect(!draft.canGenerate, "blank requirement should not generate")
        expect(draft.trimmedRequirement.isEmpty, "blank requirement should trim to empty")

        draft.requirementInput = "\n写一次难忘的挑战\t"
        expect(draft.canGenerate, "non-empty requirement should generate")
        expect(draft.trimmedRequirement == "写一次难忘的挑战", "requirement should trim surrounding whitespace")
    }

    private static func testOnlyChineseWritingIsAvailable() {
        expect(WritingLanguage.availableCases == [.chinese], "only Chinese writing should be available")
    }

    private static func testOnlyChineseWritingPromptSettingsAreAvailable() {
        expect(
            WritingPromptConfiguration.availableCases == [.chineseGeneration, .chineseReview],
            "only Chinese writing prompt settings should be available"
        )
    }

    private static func testLegacyEnglishWritingLanguageRemainsDecodable() {
        let encodedLanguage = Data("\"english\"".utf8)
        let decodedLanguage = try? JSONDecoder().decode(WritingLanguage.self, from: encodedLanguage)
        expect(decodedLanguage == .english, "legacy English writing data should remain decodable")
    }

    private static func testDeletionSelectionIgnoresInvalidOffsets() {
        let first = makePrompt(title: "A", requirement: "A")
        let second = makePrompt(title: "B", requirement: "B")
        let ids = WritingPromptDeletionSelection.targetIDs(
            offsets: IndexSet([0, 4, 1]),
            visiblePrompts: [first, second]
        )

        expect(ids == [first.id, second.id], "deletion selection should keep valid offsets only")
    }
}
