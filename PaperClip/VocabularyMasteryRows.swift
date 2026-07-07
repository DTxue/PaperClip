import Foundation

struct VocabularyMasteryRowData: Identifiable {
    let card: VocabularyCard
    let termState: VocabularyMemoryState?
    let definitionState: VocabularyMemoryState?

    let termFSRS: Double
    let termWeightedResult: VocabularyWeightedMasteryResult
    let termMastery: Double

    let definitionFSRS: Double
    let definitionWeightedResult: VocabularyWeightedMasteryResult
    let definitionMastery: Double

    var id: UUID { card.id }

    var averageMastery: Double {
        (termMastery + definitionMastery) / 2
    }

    var dueDirectionCount: Int {
        let termDue = (termState?.dueDate ?? .distantPast) <= .now ? 1 : 0
        let definitionDue = (definitionState?.dueDate ?? .distantPast) <= .now ? 1 : 0
        return termDue + definitionDue
    }
}

enum VocabularyMasteryRowBuilder {
    static func rows(
        cards: [VocabularyCard],
        states: [VocabularyMemoryState],
        logs: [VocabularyReviewLog],
        deck: VocabularyDeck
    ) -> [VocabularyMasteryRowData] {
        let stateIndex = VocabularyMemoryStateIndex(states)
        let logIndex = VocabularyReviewLogIndex(logs)
        return cards
            .map { row(for: $0, deck: deck, stateIndex: stateIndex, logIndex: logIndex) }
            .sorted {
                $0.averageMastery != $1.averageMastery
                    ? $0.averageMastery < $1.averageMastery
                    : $0.card.createdAt < $1.card.createdAt
        }
    }

    static func averageMastery(for rows: [VocabularyMasteryRowData]) -> Double {
        guard !rows.isEmpty else { return 0 }
        let total = rows.reduce(0) { $0 + $1.averageMastery }
        return total / Double(rows.count)
    }

    static func dueDirectionCount(for rows: [VocabularyMasteryRowData]) -> Int {
        rows.reduce(0) { $0 + $1.dueDirectionCount }
    }

    static func recentLogLimit(cardCount: Int) -> Int {
        min(5_000, max(300, cardCount * 60))
    }

    private static func row(
        for card: VocabularyCard,
        deck: VocabularyDeck,
        stateIndex: VocabularyMemoryStateIndex,
        logIndex: VocabularyReviewLogIndex
    ) -> VocabularyMasteryRowData {
        let termState = stateIndex.state(for: card.id, direction: .termToDefinition)
        let definitionState = stateIndex.state(for: card.id, direction: .definitionToTerm)

        let termFSRS = retrievability(for: termState, deck: deck)
        let termLogs = logIndex.logs(for: card.id, direction: .termToDefinition)
        let termWeighted = VocabularyWeightedMasteryCalculator.calculate(sortedNewestFirstLogs: termLogs)
        let termMastery = termFSRS * termWeighted.weightedMastery

        let definitionFSRS = retrievability(for: definitionState, deck: deck)
        let definitionLogs = logIndex.logs(for: card.id, direction: .definitionToTerm)
        let definitionWeighted = VocabularyWeightedMasteryCalculator.calculate(sortedNewestFirstLogs: definitionLogs)
        let definitionMastery = definitionFSRS * definitionWeighted.weightedMastery

        return VocabularyMasteryRowData(
            card: card,
            termState: termState,
            definitionState: definitionState,
            termFSRS: termFSRS,
            termWeightedResult: termWeighted,
            termMastery: termMastery,
            definitionFSRS: definitionFSRS,
            definitionWeightedResult: definitionWeighted,
            definitionMastery: definitionMastery
        )
    }

    private static func retrievability(for state: VocabularyMemoryState?, deck: VocabularyDeck) -> Double {
        guard let state else { return 0 }
        return VocabularyMemoryScheduler.currentRetrievability(state: state, deck: deck)
    }
}
