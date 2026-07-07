import Foundation
import SwiftData

extension ModelContext {
    func fetchRecentWritingDrafts(
        language: WritingLanguage,
        limit: Int,
        propertiesToFetch: [PartialKeyPath<WritingDraft>] = []
    ) throws -> [WritingDraft] {
        let languageRaw = language.rawValue
        let descriptor = FetchDescriptor<WritingDraft>(
            predicate: #Predicate<WritingDraft> { draft in
                draft.languageRaw == languageRaw
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try fetchConfigured(descriptor, limit: limit, propertiesToFetch: propertiesToFetch)
    }

    func fetchRecentWritingDrafts(
        language: WritingLanguage,
        promptIDs: [UUID],
        limit: Int,
        propertiesToFetch: [PartialKeyPath<WritingDraft>] = []
    ) throws -> [WritingDraft] {
        guard !promptIDs.isEmpty else { return [] }
        let languageRaw = language.rawValue
        let descriptor = FetchDescriptor<WritingDraft>(
            predicate: #Predicate<WritingDraft> { draft in
                draft.languageRaw == languageRaw && promptIDs.contains(draft.promptID)
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try fetchConfigured(descriptor, limit: limit, propertiesToFetch: propertiesToFetch)
    }

    func fetchLatestWritingDraft(promptID: UUID) throws -> WritingDraft? {
        let descriptor = FetchDescriptor<WritingDraft>(
            predicate: #Predicate<WritingDraft> { draft in
                draft.promptID == promptID
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try fetchFirst(descriptor)
    }
}
