import Foundation
import SwiftData

extension ModelContext {
    func fetchVocabularyStudySession(id: UUID) throws -> VocabularyStudySession? {
        let descriptor = FetchDescriptor<VocabularyStudySession>(
            predicate: #Predicate<VocabularyStudySession> { session in
                session.id == id
            }
        )
        return try fetchFirst(descriptor)
    }

    func fetchVocabularyScoreSessions(
        deckID: UUID,
        limit: Int,
        propertiesToFetch: [PartialKeyPath<VocabularyStudySession>] = []
    ) throws -> [VocabularyStudySession] {
        var descriptor = FetchDescriptor<VocabularyStudySession>(
                predicate: #Predicate<VocabularyStudySession> { session in
                    session.deckID == deckID
                    && (session.kind == "学习"
                        || session.kind == "测验"
                        || session.kind == "英文释义手写"
                        || session.kind == "语境练习"
                        || session.kind == "test")
                },
            sortBy: [SortDescriptor(\.endedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetch(descriptor)
    }
}
