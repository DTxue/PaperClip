import Foundation
import SwiftData

extension ModelContext {
    func fetchLatestVocabularyTestDraft(deckID: UUID, mode: String) throws -> VocabularyTestDraft? {
        let descriptor = FetchDescriptor<VocabularyTestDraft>(
            predicate: #Predicate<VocabularyTestDraft> { draft in
                draft.deckID == deckID && draft.mode == mode
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try fetchFirst(descriptor)
    }

    @discardableResult
    func deleteVocabularyTestDrafts(deckID: UUID, mode: String) throws -> Int {
        try deleteFetchedVocabularyRows(FetchDescriptor<VocabularyTestDraft>(
            predicate: #Predicate<VocabularyTestDraft> { draft in
                draft.deckID == deckID && draft.mode == mode
            }
        ), fetching: VocabularyTestDraft.deletionPropertiesToFetch)
    }
}
