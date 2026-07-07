import SwiftData

enum WritingReviewTransaction {
    @MainActor
    static func saveState(in modelContext: ModelContext) throws {
        try modelContext.saveOrRollbackIfNeeded()
    }

    @MainActor
    static func insertCompletedReview(
        _ review: WritingReview,
        draft: WritingDraft,
        in modelContext: ModelContext
    ) throws {
        modelContext.insert(review)
        draft.reviewStatus = .graded
        draft.updatedAt = .now
        try modelContext.saveOrRollbackIfNeeded()
    }
}
