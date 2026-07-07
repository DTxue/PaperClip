import Foundation
import SwiftData

struct WritingPromptListData {
    let prompts: [WritingPromptRowData]
    let drafts: [WritingDraftRowData]
    let reviews: [WritingReviewRowData]
}

enum WritingPromptListDataLoader {
    static func load(language: WritingLanguage, modelContext: ModelContext) throws -> WritingPromptListData {
        let prompts = try modelContext.fetchWritingPrompts(
            language: language,
            propertiesToFetch: WritingPromptRowData.propertiesToFetch
        ).map(WritingPromptRowData.init)
        let metadata = try loadMetadata(
            language: language,
            promptIDs: prompts.map(\.id),
            modelContext: modelContext
        )
        return WritingPromptListData(
            prompts: prompts,
            drafts: metadata.drafts,
            reviews: metadata.reviews
        )
    }

    private static func loadMetadata(
        language: WritingLanguage,
        promptIDs: [UUID],
        modelContext: ModelContext
    ) throws -> (drafts: [WritingDraftRowData], reviews: [WritingReviewRowData]) {
        let limit = WritingRecentMetadataFetchPlan.limit(promptCount: promptIDs.count)
        guard limit > 0 else { return ([], []) }

        let drafts = try modelContext.fetchRecentWritingDrafts(
            language: language,
            promptIDs: promptIDs,
            limit: limit,
            propertiesToFetch: WritingDraftRowData.propertiesToFetch
        ).map(WritingDraftRowData.init)
        let reviews = try modelContext.fetchRecentWritingReviews(
            language: language,
            promptIDs: promptIDs,
            limit: limit,
            propertiesToFetch: WritingReviewRowData.propertiesToFetch
        ).map(WritingReviewRowData.init)
        return (drafts, reviews)
    }
}
