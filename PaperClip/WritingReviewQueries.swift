import Foundation
import SwiftData

extension ModelContext {
    func fetchRecentWritingReviews(
        language: WritingLanguage,
        limit: Int,
        propertiesToFetch: [PartialKeyPath<WritingReview>] = []
    ) throws -> [WritingReview] {
        let languageRaw = language.rawValue
        let descriptor = FetchDescriptor<WritingReview>(
            predicate: #Predicate<WritingReview> { review in
                review.languageRaw == languageRaw
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try fetchConfigured(descriptor, limit: limit, propertiesToFetch: propertiesToFetch)
    }

    func fetchRecentWritingReviews(
        language: WritingLanguage,
        promptIDs: [UUID],
        limit: Int,
        propertiesToFetch: [PartialKeyPath<WritingReview>] = []
    ) throws -> [WritingReview] {
        guard !promptIDs.isEmpty else { return [] }
        let languageRaw = language.rawValue
        let descriptor = FetchDescriptor<WritingReview>(
            predicate: #Predicate<WritingReview> { review in
                review.languageRaw == languageRaw && promptIDs.contains(review.promptID)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try fetchConfigured(descriptor, limit: limit, propertiesToFetch: propertiesToFetch)
    }

    func fetchWritingReviews(
        promptID: UUID,
        limit: Int,
        propertiesToFetch: [PartialKeyPath<WritingReview>] = []
    ) throws -> [WritingReview] {
        let descriptor = FetchDescriptor<WritingReview>(
            predicate: #Predicate<WritingReview> { review in
                review.promptID == promptID
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try fetchConfigured(descriptor, limit: limit, propertiesToFetch: propertiesToFetch)
    }

    func fetchWritingReview(id: UUID) throws -> WritingReview? {
        let descriptor = FetchDescriptor<WritingReview>(
            predicate: #Predicate<WritingReview> { review in
                review.id == id
            }
        )
        return try fetchFirst(descriptor)
    }
}
