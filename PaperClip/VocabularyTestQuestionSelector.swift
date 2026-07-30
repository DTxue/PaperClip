import Foundation

enum VocabularyTestQuestionSelectionStrategy: Equatable {
    case prioritized
    case random
    case custom(cardIDs: Set<UUID>)

    var usesReviewPriority: Bool {
        self == .prioritized
    }
}

enum VocabularyTestQuestionSelector {
    static func recentReviewLogLimit(cardCount: Int) -> Int {
        min(1_000, max(100, cardCount * 3))
    }

    static func questions(
        deck: VocabularyDeck,
        deckCards: [VocabularyCard],
        states: [VocabularyMemoryState],
        recentLogs: [VocabularyReviewLog],
        limit: Int
    ) -> [VocabularyCard] {
        let cappedLimit = min(limit, deckCards.count)
        guard cappedLimit > 0 else { return [] }

        let priorities = VocabularyTestQuestionPriority(
            deck: deck,
            states: states,
            recentLogs: recentLogs
        )
        if cappedLimit == deckCards.count {
            var candidates: [(card: VocabularyCard, priority: Double)] = []
            candidates.reserveCapacity(deckCards.count)
            for card in deckCards {
                candidates.append((
                    card: card,
                    priority: priorities.priority(for: card)
                ))
            }
            candidates.sort { $0.priority > $1.priority }
            return candidates.map(\.card)
        }

        var topCandidates: [(card: VocabularyCard, priority: Double)] = []
        topCandidates.reserveCapacity(cappedLimit)
        for card in deckCards {
            let candidate = (
                card: card,
                priority: priorities.priority(for: card)
            )
            if topCandidates.count < cappedLimit {
                topCandidates.append(candidate)
            } else if let lowestIndex = topCandidates.indices.min(by: {
                topCandidates[$0].priority < topCandidates[$1].priority
            }), candidate.priority > topCandidates[lowestIndex].priority {
                topCandidates[lowestIndex] = candidate
            }
        }
        topCandidates.sort { $0.priority > $1.priority }
        return topCandidates.map(\.card)
    }

    static func randomQuestions(
        from deckCards: [VocabularyCard],
        limit: Int,
        shuffle: ([VocabularyCard]) -> [VocabularyCard] = { $0.shuffled() }
    ) -> [VocabularyCard] {
        let cappedLimit = min(max(0, limit), deckCards.count)
        guard cappedLimit > 0 else { return [] }
        return Array(shuffle(deckCards).prefix(cappedLimit))
    }

    static func customQuestions(
        from deckCards: [VocabularyCard],
        selectedCardIDs: Set<UUID>
    ) -> [VocabularyCard] {
        deckCards.filter { selectedCardIDs.contains($0.id) }
    }
}
