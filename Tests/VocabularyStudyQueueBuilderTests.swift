import Foundation

@main
struct VocabularyStudyQueueBuilderTests {
    static func main() {
        testDueInsertionKeepsEarliestLimitedCards()
        testWeakInsertionKeepsHighestPriorityCards()
        testMasteryPriorityUsesProvidedNow()
        testCustomFSRSParametersDecodeFromDeckJSON()
        testInvalidFSRSParametersFallBackToDefaults()
        testBuildQueueOrdersDueFreshThenWeakCards()
        testBuildQueueStopsAtMaximumCount()
        testBuildQueueReturnsEmptyForNonPositiveMaximum()
        testNegativeDailyNewLimitSkipsFreshSampling()
        testPlanIndexesFirstStateAndClassifiesDueAndFreshCards()
        testPlanNormalizesNegativeMaximum()
        testFlashcardQueueIncludesFutureAndFreshCards()
        print("VocabularyStudyQueueBuilderTests: 16 passed")
    }

    private static func testDueInsertionKeepsEarliestLimitedCards() {
        let deckID = UUID()
        let late = makeCard(deckID: deckID, term: "late")
        let early = makeCard(deckID: deckID, term: "early")
        let middle = makeCard(deckID: deckID, term: "middle")
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var due: [(card: VocabularyCard, dueDate: Date)] = []

        VocabularyStudyQueueRanking.insertDueCard((late, base.addingTimeInterval(30)), into: &due, limit: 2)
        VocabularyStudyQueueRanking.insertDueCard((early, base.addingTimeInterval(10)), into: &due, limit: 2)
        VocabularyStudyQueueRanking.insertDueCard((middle, base.addingTimeInterval(20)), into: &due, limit: 2)

        expect(due.map { $0.card.term } == ["early", "middle"])
    }

    private static func testWeakInsertionKeepsHighestPriorityCards() {
        let deckID = UUID()
        let low = makeCard(deckID: deckID, term: "low")
        let high = makeCard(deckID: deckID, term: "high")
        let middle = makeCard(deckID: deckID, term: "middle")
        var weak: [(card: VocabularyCard, priority: Double)] = []

        VocabularyStudyQueueRanking.insertWeakCard((low, 1), into: &weak, limit: 2)
        VocabularyStudyQueueRanking.insertWeakCard((high, 3), into: &weak, limit: 2)
        VocabularyStudyQueueRanking.insertWeakCard((middle, 2), into: &weak, limit: 2)

        expect(weak.map { $0.card.term } == ["high", "middle"])
    }

    private static func testMasteryPriorityUsesProvidedNow() {
        let deck = VocabularyDeck(title: "Test")
        let card = makeCard(deckID: deck.id, term: "word")
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let futureState = VocabularyMemoryState(
            deckID: deck.id,
            cardID: card.id,
            direction: .definitionToTerm,
            stage: .review,
            dueDate: now.addingTimeInterval(60),
            lastReviewDate: now,
            stability: 1,
            difficulty: 1,
            lapseCount: 0
        )
        let dueState = VocabularyMemoryState(
            deckID: deck.id,
            cardID: card.id,
            direction: .definitionToTerm,
            stage: .review,
            dueDate: now,
            lastReviewDate: now,
            stability: 1,
            difficulty: 1,
            lapseCount: 0
        )

        let futurePriority = VocabularyStudyQueueRanking.masteryPriority(
            card,
            state: futureState,
            deck: deck,
            now: now
        )
        let duePriority = VocabularyStudyQueueRanking.masteryPriority(
            card,
            state: dueState,
            deck: deck,
            now: now
        )
        expect(duePriority - futurePriority >= 999)
    }

    private static func testCustomFSRSParametersDecodeFromDeckJSON() {
        let parameters = VocabularySchedulingCore.defaultParameters.enumerated().map {
            $0.element + Double($0.offset + 1) / 1_000
        }
        let deck = VocabularyDeck(
            title: "Custom",
            fsrsParametersJSON: VocabularyJSONStorage.encode(parameters)
        )

        expect(VocabularyMemoryRetrievability.parameters(for: deck) == parameters)
    }

    private static func testInvalidFSRSParametersFallBackToDefaults() {
        let malformedDeck = VocabularyDeck(title: "Broken", fsrsParametersJSON: "not-json")
        let shortDeck = VocabularyDeck(
            title: "Short",
            fsrsParametersJSON: VocabularyJSONStorage.encode([1.0, 2.0])
        )

        expect(
            VocabularyMemoryRetrievability.parameters(for: malformedDeck)
                == VocabularySchedulingCore.defaultParameters
        )
        expect(
            VocabularyMemoryRetrievability.parameters(for: shortDeck)
                == VocabularySchedulingCore.defaultParameters
        )
    }

    private static func testBuildQueueOrdersDueFreshThenWeakCards() {
        let deck = VocabularyDeck(title: "Test", dailyNewLimit: 1)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let dueLate = makeCard(deckID: deck.id, term: "due-late")
        let dueEarly = makeCard(deckID: deck.id, term: "due-early")
        let freshA = makeCard(deckID: deck.id, term: "fresh-a")
        let freshB = makeCard(deckID: deck.id, term: "fresh-b")
        let weak = makeCard(deckID: deck.id, term: "weak")
        let steady = makeCard(deckID: deck.id, term: "steady")

        let queue = VocabularyStudyQueueBuilder.buildQueue(
            cards: [freshA, dueLate, weak, freshB, steady, dueEarly],
            states: [
                makeState(deckID: deck.id, cardID: dueLate.id, dueDate: now.addingTimeInterval(-20), lapseCount: 0),
                makeState(deckID: deck.id, cardID: dueEarly.id, dueDate: now.addingTimeInterval(-60), lapseCount: 0),
                makeState(deckID: deck.id, cardID: weak.id, dueDate: now.addingTimeInterval(3_600), lapseCount: 5),
                makeState(deckID: deck.id, cardID: steady.id, dueDate: now.addingTimeInterval(3_600), lapseCount: 0)
            ],
            deck: deck,
            maximumQueueCount: 4,
            now: now,
            freshSampler: { cards, limit in Array(cards.prefix(limit)) }
        )

        expect(queue.map(\.term) == ["due-early", "due-late", "fresh-a", "fresh-b"])
    }

    private static func testBuildQueueStopsAtMaximumCount() {
        let deck = VocabularyDeck(title: "Test", dailyNewLimit: 5)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let first = makeCard(deckID: deck.id, term: "first")
        let second = makeCard(deckID: deck.id, term: "second")
        let third = makeCard(deckID: deck.id, term: "third")

        let queue = VocabularyStudyQueueBuilder.buildQueue(
            cards: [third, second, first],
            states: [
                makeState(deckID: deck.id, cardID: third.id, dueDate: now.addingTimeInterval(-10), lapseCount: 0),
                makeState(deckID: deck.id, cardID: second.id, dueDate: now.addingTimeInterval(-20), lapseCount: 0),
                makeState(deckID: deck.id, cardID: first.id, dueDate: now.addingTimeInterval(-30), lapseCount: 0)
            ],
            deck: deck,
            maximumQueueCount: 2,
            now: now,
            freshSampler: { cards, limit in Array(cards.prefix(limit)) }
        )

        expect(queue.map(\.term) == ["first", "second"])
    }

    private static func testBuildQueueReturnsEmptyForNonPositiveMaximum() {
        let deck = VocabularyDeck(title: "Test")
        let card = makeCard(deckID: deck.id, term: "word")

        let zeroQueue = VocabularyStudyQueueBuilder.buildQueue(
            cards: [card],
            states: [],
            deck: deck,
            maximumQueueCount: 0
        )
        let negativeQueue = VocabularyStudyQueueBuilder.buildQueue(
            cards: [card],
            states: [],
            deck: deck,
            maximumQueueCount: -1
        )

        expect(zeroQueue.isEmpty)
        expect(negativeQueue.isEmpty)
    }

    private static func testNegativeDailyNewLimitSkipsFreshSampling() {
        let deck = VocabularyDeck(title: "Test", dailyNewLimit: -5)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let fresh = makeCard(deckID: deck.id, term: "fresh")
        let weak = makeCard(deckID: deck.id, term: "weak")

        let queue = VocabularyStudyQueueBuilder.buildQueue(
            cards: [fresh, weak],
            states: [
                makeState(deckID: deck.id, cardID: weak.id, dueDate: now.addingTimeInterval(3_600), lapseCount: 3)
            ],
            deck: deck,
            maximumQueueCount: 2,
            now: now,
            freshSampler: { cards, limit in
                expect(limit == 0)
                return Array(cards.prefix(limit))
            }
        )

        expect(queue.map(\.term) == ["fresh", "weak"])
    }

    private static func testPlanIndexesFirstStateAndClassifiesDueAndFreshCards() {
        let deck = VocabularyDeck(title: "Test")
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let due = makeCard(deckID: deck.id, term: "due")
        let fresh = makeCard(deckID: deck.id, term: "fresh")
        let duplicateLaterState = makeState(deckID: deck.id, cardID: due.id, dueDate: now.addingTimeInterval(100), lapseCount: 0)
        let dueState = makeState(deckID: deck.id, cardID: due.id, dueDate: now.addingTimeInterval(-100), lapseCount: 0)

        let plan = VocabularyStudyQueuePlan(
            cards: [due, fresh],
            states: [dueState, duplicateLaterState],
            maximumQueueCount: 10,
            now: now
        )

        expect(plan.queueLimit == 10)
        expect(plan.stateByCardID[due.id]?.dueDate == dueState.dueDate)
        expect(plan.due.map { $0.card.term } == ["due"])
        expect(plan.freshCandidates.map(\.term) == ["fresh"])
    }

    private static func testPlanNormalizesNegativeMaximum() {
        let deck = VocabularyDeck(title: "Test")
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let card = makeCard(deckID: deck.id, term: "word")
        let plan = VocabularyStudyQueuePlan(
            cards: [card],
            states: [],
            maximumQueueCount: -1,
            now: now
        )

        let queue = plan.makeQueue(cards: [card], deck: deck, now: now) { cards, limit in
            expect(limit == 0)
            return cards
        }

        expect(plan.queueLimit == 0)
        expect(queue.isEmpty)
    }

    private static func testFlashcardQueueIncludesFutureAndFreshCards() {
        let deck = VocabularyDeck(title: "Test", dailyNewLimit: 1)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let future = makeCard(deckID: deck.id, term: "future")
        let dueLate = makeCard(deckID: deck.id, term: "due-late")
        let freshA = makeCard(deckID: deck.id, term: "fresh-a")
        let dueEarly = makeCard(deckID: deck.id, term: "due-early")
        let freshB = makeCard(deckID: deck.id, term: "fresh-b")

        let queue = VocabularyFlashcardQueue.orderedCards(
            cards: [future, dueLate, freshA, dueEarly, freshB],
            states: [
                makeState(deckID: deck.id, cardID: future.id, dueDate: now.addingTimeInterval(3_600), lapseCount: 0),
                makeState(deckID: deck.id, cardID: dueLate.id, dueDate: now.addingTimeInterval(-10), lapseCount: 0),
                makeState(deckID: deck.id, cardID: dueEarly.id, dueDate: now.addingTimeInterval(-30), lapseCount: 0)
            ],
            direction: .definitionToTerm,
            now: now
        )

        expect(queue.map(\.term) == ["due-early", "due-late", "future", "fresh-a", "fresh-b"])
    }

    private static func makeCard(deckID: UUID, term: String) -> VocabularyCard {
        VocabularyCard(deckID: deckID, term: term, definition: "\(term)-definition")
    }

    private static func makeState(
        deckID: UUID,
        cardID: UUID,
        dueDate: Date,
        lapseCount: Int
    ) -> VocabularyMemoryState {
        VocabularyMemoryState(
            deckID: deckID,
            cardID: cardID,
            direction: .definitionToTerm,
            stage: .review,
            dueDate: dueDate,
            lastReviewDate: dueDate,
            stability: 1,
            difficulty: 1,
            lapseCount: lapseCount
        )
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError("Expectation failed", file: file, line: line)
        }
    }
}
