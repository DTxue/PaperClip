import Foundation

struct VocabularyTestQuestionPriority {
    private let deck: VocabularyDeck
    private let stateByCardID: [UUID: VocabularyMemoryState]
    private let latestLogByCardID: [UUID: VocabularyReviewLog]

    init(
        deck: VocabularyDeck,
        states: [VocabularyMemoryState],
        recentLogs: [VocabularyReviewLog]
    ) {
        self.deck = deck
        stateByCardID = Dictionary(
            states.lazy.map { ($0.cardID, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        latestLogByCardID = Dictionary(
            recentLogs.lazy.map { ($0.cardID, $0) },
            uniquingKeysWith: { lhs, rhs in
                lhs.reviewedAt >= rhs.reviewedAt ? lhs : rhs
            }
        )
    }

    func priority(for card: VocabularyCard, now: Date = .now) -> Double {
        guard let state = stateByCardID[card.id] else {
            return 2_000 + Self.tiebreaker(card.id)
        }

        let retrievability = VocabularyMemoryScheduler.currentRetrievability(
            state: state,
            deck: deck
        )
        let overdueDays = max(0, now.timeIntervalSince(state.dueDate) / 86_400)
        let dueBonus: Double = state.dueDate <= now ? 1_500 + min(overdueDays, 30) * 20 : 0
        let recentWrongBonus: Double = latestLogByCardID[card.id]?.rating == VocabularyReviewRating.again.rawValue ? 600 : 0
        let isLearningStage = state.stage == VocabularyMemoryStage.learning.rawValue
            || state.stage == VocabularyMemoryStage.relearning.rawValue
        let stageBonus: Double = isLearningStage ? 250 : 0
        let memoryPenalty = (1 - retrievability) * 700
        let lapsePenalty = Double(state.lapseCount) * 100
        let difficultyPenalty = state.difficulty * 30

        return dueBonus
            + recentWrongBonus
            + stageBonus
            + memoryPenalty
            + lapsePenalty
            + difficultyPenalty
            + Self.tiebreaker(card.id)
    }

    private static func tiebreaker(_ id: UUID) -> Double {
        var hash: UInt64 = 14_695_981_039_346_656_037
        withUnsafeBytes(of: id.uuid) { bytes in
            for byte in bytes {
                hash ^= UInt64(byte)
                hash &*= 1_099_511_628_211
            }
        }
        return Double(hash % 1_000) / 1_000
    }
}
