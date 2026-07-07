import Foundation

@main
struct VocabularyHomeSnapshotTests {
    static func main() {
        testCountsOnlyCardsInVisibleDecks()
        testDueCountIgnoresFutureStatesForUnknownDecksAndCards()
        testFutureDirectionKeysAreDeduplicated()
        testEmptyDecksKeepZeroCounts()
        print("VocabularyHomeSnapshotTests: 4 passed")
    }

    private static func testCountsOnlyCardsInVisibleDecks() {
        let deckA = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let deckB = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let otherDeck = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        let cardA = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let cardB = UUID(uuidString: "00000000-0000-0000-0000-000000000102")!
        let ignoredCard = UUID(uuidString: "00000000-0000-0000-0000-000000000103")!

        let snapshot = VocabularyHomeSnapshot(
            deckIDs: [deckA, deckB],
            cards: [
                VocabularyHomeCardCountInput(id: cardA, deckID: deckA),
                VocabularyHomeCardCountInput(id: cardB, deckID: deckA),
                VocabularyHomeCardCountInput(id: ignoredCard, deckID: otherDeck)
            ],
            futureStates: []
        )

        expect(snapshot.totalCardCount == 2)
        expect(snapshot.cardCountByDeckID[deckA] == 2)
        expect(snapshot.cardCountByDeckID[deckB] == 0)
        expect(snapshot.cardCountByDeckID[otherDeck] == nil)
        expect(snapshot.dueCount == 2 * VocabularyDirection.allCases.count)
    }

    private static func testDueCountIgnoresFutureStatesForUnknownDecksAndCards() {
        let deckID = UUID(uuidString: "00000000-0000-0000-0000-000000000011")!
        let cardID = UUID(uuidString: "00000000-0000-0000-0000-000000000111")!
        let missingCardID = UUID(uuidString: "00000000-0000-0000-0000-000000000112")!
        let otherDeckID = UUID(uuidString: "00000000-0000-0000-0000-000000000012")!

        let snapshot = VocabularyHomeSnapshot(
            deckIDs: [deckID],
            cards: [
                VocabularyHomeCardCountInput(id: cardID, deckID: deckID)
            ],
            futureStates: [
                VocabularyHomeFutureStateInput(
                    deckID: deckID,
                    cardID: cardID,
                    direction: VocabularyDirection.termToDefinition.rawValue
                ),
                VocabularyHomeFutureStateInput(
                    deckID: deckID,
                    cardID: missingCardID,
                    direction: VocabularyDirection.definitionToTerm.rawValue
                ),
                VocabularyHomeFutureStateInput(
                    deckID: otherDeckID,
                    cardID: cardID,
                    direction: VocabularyDirection.definitionToTerm.rawValue
                ),
                VocabularyHomeFutureStateInput(
                    deckID: nil,
                    cardID: cardID,
                    direction: VocabularyDirection.definitionToTerm.rawValue
                )
            ]
        )

        expect(snapshot.totalCardCount == 1)
        expect(snapshot.dueCount == VocabularyDirection.allCases.count - 1)
    }

    private static func testFutureDirectionKeysAreDeduplicated() {
        let deckID = UUID(uuidString: "00000000-0000-0000-0000-000000000021")!
        let cardID = UUID(uuidString: "00000000-0000-0000-0000-000000000121")!

        let snapshot = VocabularyHomeSnapshot(
            deckIDs: [deckID],
            cards: [
                VocabularyHomeCardCountInput(id: cardID, deckID: deckID)
            ],
            futureStates: [
                VocabularyHomeFutureStateInput(
                    deckID: deckID,
                    cardID: cardID,
                    direction: VocabularyDirection.termToDefinition.rawValue
                ),
                VocabularyHomeFutureStateInput(
                    deckID: deckID,
                    cardID: cardID,
                    direction: VocabularyDirection.termToDefinition.rawValue
                )
            ]
        )

        expect(snapshot.dueCount == VocabularyDirection.allCases.count - 1)
    }

    private static func testEmptyDecksKeepZeroCounts() {
        let deckID = UUID(uuidString: "00000000-0000-0000-0000-000000000031")!
        let snapshot = VocabularyHomeSnapshot(
            deckIDs: [deckID],
            cards: [],
            futureStates: []
        )

        expect(snapshot.totalCardCount == 0)
        expect(snapshot.dueCount == 0)
        expect(snapshot.cardCountByDeckID[deckID] == 0)
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
