import Foundation

@main
struct VocabularyDeckSnapshotTests {
    static func main() {
        testSearchFiltersVisibleCards()
        testDueDirectionCountUsesInjectedDate()
        print("VocabularyDeckSnapshotTests: 8 passed")
    }

    private static func testSearchFiltersVisibleCards() {
        let matchingTerm = VocabularyCardRowData(
            id: UUID(),
            term: "memory",
            definition: "记忆"
        )
        let matchingDefinition = VocabularyCardRowData(
            id: UUID(),
            term: "forget",
            definition: "遗忘 memory"
        )
        let hidden = VocabularyCardRowData(
            id: UUID(),
            term: "apple",
            definition: "苹果"
        )

        let snapshot = VocabularyDeckSnapshot(
            cards: [matchingTerm, matchingDefinition, hidden],
            states: [],
            todayReviewCount: 7,
            searchText: "memo",
            now: Date(timeIntervalSince1970: 100)
        )

        expect(snapshot.visibleCards.map(\.id) == [matchingTerm.id, matchingDefinition.id])
        expect(snapshot.todayReviewCount == 7)
        expect(snapshot.dueDirectionCount == 6)
    }

    private static func testDueDirectionCountUsesInjectedDate() {
        let cardID = UUID()
        let card = VocabularyCardRowData(
            id: cardID,
            term: "term",
            definition: "definition"
        )
        let now = Date(timeIntervalSince1970: 1_000)
        let past = Date(timeIntervalSince1970: 900)
        let future = Date(timeIntervalSince1970: 1_100)
        let states = [
            VocabularyMemoryState(
                cardID: cardID,
                direction: .termToDefinition,
                dueDate: past
            ),
            VocabularyMemoryState(
                cardID: cardID,
                direction: .definitionToTerm,
                dueDate: future
            )
        ]

        let snapshot = VocabularyDeckSnapshot(
            cards: [card],
            states: states,
            todayReviewCount: 0,
            searchText: "",
            now: now
        )

        expect(snapshot.visibleCards == [card])
        expect(snapshot.dueDirectionCount == 1)
        expect(card.matchesSearch(""))
        expect(card.matchesSearch("TERM"))
        expect(card.matchesSearch("def"))
        expect(!card.matchesSearch("missing"))
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
