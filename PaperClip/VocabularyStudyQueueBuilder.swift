import Foundation

enum VocabularyStudyQueueBuilder {
    typealias FreshSampler = (_ cards: [VocabularyCard], _ limit: Int) -> [VocabularyCard]

    static func buildQueue(
        cards allCards: [VocabularyCard],
        states: [VocabularyMemoryState],
        deck: VocabularyDeck,
        maximumQueueCount: Int,
        now: Date = .now,
        freshSampler: FreshSampler = VocabularyStudyQueueRanking.randomSample
    ) -> [VocabularyCard] {
        VocabularyStudyQueuePlan(
            cards: allCards,
            states: states,
            maximumQueueCount: maximumQueueCount,
            now: now
        ).makeQueue(
            cards: allCards,
            deck: deck,
            now: now,
            freshSampler: freshSampler
        )
    }
}
