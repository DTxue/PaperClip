import Foundation

enum VocabularyStudyQueueRanking {
    static func insertDueCard(
        _ item: (card: VocabularyCard, dueDate: Date),
        into due: inout [(card: VocabularyCard, dueDate: Date)],
        limit: Int
    ) {
        guard limit > 0 else { return }
        let insertIndex = due.firstIndex { item.dueDate < $0.dueDate } ?? due.count
        guard insertIndex < limit else { return }
        due.insert(item, at: insertIndex)
        if due.count > limit {
            due.removeLast()
        }
    }

    static func insertWeakCard(
        _ item: (card: VocabularyCard, priority: Double),
        into weak: inout [(card: VocabularyCard, priority: Double)],
        limit: Int
    ) {
        guard limit > 0 else { return }
        let insertIndex = weak.firstIndex { item.priority > $0.priority } ?? weak.count
        guard insertIndex < limit else { return }
        weak.insert(item, at: insertIndex)
        if weak.count > limit {
            weak.removeLast()
        }
    }

    static func masteryPriority(
        _ card: VocabularyCard,
        state: VocabularyMemoryState?,
        deck: VocabularyDeck,
        now: Date
    ) -> Double {
        guard let state else { return 1_000 }
        let retrievability = VocabularyMemoryRetrievability.current(
            state: state,
            deck: deck,
            now: now
        )
        let dueBonus: Double = state.dueDate <= now ? 1_000 : 0
        let isLearningStage = state.stage == VocabularyMemoryStage.learning.rawValue
            || state.stage == VocabularyMemoryStage.relearning.rawValue
        let stageBonus: Double = isLearningStage ? 200 : 0
        let memoryPenalty = (1 - retrievability) * 500
        let lapsePenalty = Double(state.lapseCount) * 80
        let difficultyPenalty = state.difficulty * 20
        return dueBonus + stageBonus + memoryPenalty + lapsePenalty + difficultyPenalty
    }

    static func randomSample(from cards: [VocabularyCard], limit: Int) -> [VocabularyCard] {
        guard limit > 0, !cards.isEmpty else { return [] }
        if cards.count <= limit { return cards.shuffled() }

        var sample: [VocabularyCard] = []
        sample.reserveCapacity(limit)
        for (index, card) in cards.enumerated() {
            if index < limit {
                sample.append(card)
                continue
            }
            let replacementIndex = Int.random(in: 0...index)
            if replacementIndex < limit {
                sample[replacementIndex] = card
            }
        }
        return sample.shuffled()
    }
}
