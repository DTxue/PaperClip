import Foundation

enum VocabularyTestQuestionRange {
    static func normalized(
        _ range: ClosedRange<Int>,
        maximumQuestionCount: Int
    ) -> ClosedRange<Int> {
        normalized(
            startQuestion: range.lowerBound,
            endQuestion: range.upperBound,
            maximumQuestionCount: maximumQuestionCount
        )
    }

    static func normalized(
        startQuestion: Int,
        endQuestion: Int,
        maximumQuestionCount: Int
    ) -> ClosedRange<Int> {
        let maximum = max(1, maximumQuestionCount)
        let lowerBound = min(max(1, min(startQuestion, endQuestion)), maximum)
        let upperBound = min(max(lowerBound, max(startQuestion, endQuestion)), maximum)
        return lowerBound...upperBound
    }

    static func validated(
        startQuestion: Int,
        questionCount: Int,
        maximumQuestionCount: Int
    ) -> ClosedRange<Int>? {
        guard maximumQuestionCount > 0,
              startQuestion > 0,
              questionCount > 0,
              startQuestion <= maximumQuestionCount,
              questionCount <= maximumQuestionCount - startQuestion + 1 else {
            return nil
        }
        return startQuestion...(startQuestion + questionCount - 1)
    }
}

enum VocabularyTestQuestionSelectionStrategy: Equatable {
    case prioritized
    case random
    case randomStandard
    case orderedRange(startQuestion: Int, endQuestion: Int)
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

    static func orderedQuestions(
        from deckCards: [VocabularyCard],
        startQuestion: Int,
        endQuestion: Int
    ) -> [VocabularyCard] {
        guard !deckCards.isEmpty else { return [] }
        let range = VocabularyTestQuestionRange.normalized(
            startQuestion: startQuestion,
            endQuestion: endQuestion,
            maximumQuestionCount: deckCards.count
        )
        let start = range.lowerBound
        let end = range.upperBound
        return Array(deckCards[(start - 1)..<end])
    }

    static func customQuestions(
        from deckCards: [VocabularyCard],
        selectedCardIDs: Set<UUID>
    ) -> [VocabularyCard] {
        deckCards.filter { selectedCardIDs.contains($0.id) }
    }
}
