import Foundation
import SwiftData

enum VocabularyStudySessionTransaction {
    @MainActor
    static func recordProgress(
        sessionID: UUID,
        deckID: UUID,
        kind: String,
        startedAt: Date,
        items: [VocabularyStudySessionItem],
        in modelContext: ModelContext
    ) throws {
        guard !items.isEmpty else { return }

        do {
            let descriptor = FetchDescriptor<VocabularyStudySession>(
                predicate: #Predicate<VocabularyStudySession> { session in
                    session.id == sessionID
                }
            )
            let endedAt = Date.now
            let metrics = VocabularyStudySessionMetrics(
                correctness: items.map(\.isCorrect)
            )

            if let session = try modelContext.fetchFirst(descriptor) {
                session.deckID = deckID
                session.kind = kind
                session.startedAt = startedAt
                session.endedAt = endedAt
                session.duration = endedAt.timeIntervalSince(startedAt)
                session.totalCount = metrics.totalCount
                session.correctCount = metrics.correctCount
                session.itemsJSON = VocabularyJSONStorage.encode(items)
            } else {
                modelContext.insert(
                    VocabularyStudySession(
                        id: sessionID,
                        deckID: deckID,
                        kind: kind,
                        startedAt: startedAt,
                        endedAt: endedAt,
                        duration: endedAt.timeIntervalSince(startedAt),
                        totalCount: metrics.totalCount,
                        correctCount: metrics.correctCount,
                        items: items
                    )
                )
            }
            try modelContext.saveOrRollbackIfNeeded()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    @MainActor
    @discardableResult
    static func recordSession(
        deckID: UUID,
        kind: String,
        startedAt: Date,
        items: [VocabularyStudySessionItem],
        in modelContext: ModelContext
    ) throws -> Bool {
        guard let session = VocabularyStudySessionDraft(
            deckID: deckID,
            kind: kind,
            startedAt: startedAt,
            items: items
        ).makeSession() else { return false }

        modelContext.insert(session)
        try modelContext.saveOrRollbackIfNeeded()
        return true
    }

    @MainActor
    static func saveProgress(in modelContext: ModelContext) throws {
        try modelContext.saveOrRollbackIfNeeded()
    }
}
