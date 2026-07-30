import Foundation

@main
struct VocabularyTestQuestionSelectorTests {
    static func main() {
        testRecentReviewLogLimitBounds()
        testNewCardsRankBeforeReviewedCards()
        testLatestAgainLogRanksAheadOfLatestGoodLog()
        testPriorityUsesLatestReviewLog()
        testRandomQuestionsUseShuffledOrderAndLimit()
        testCustomQuestionsKeepOnlySelectedCardsInDeckOrder()
        testAnsweringActionTitles()
        print("VocabularyTestQuestionSelectorTests: 7 passed")
    }

    private static func testRecentReviewLogLimitBounds() {
        expect(VocabularyTestQuestionSelector.recentReviewLogLimit(cardCount: 0) == 100)
        expect(VocabularyTestQuestionSelector.recentReviewLogLimit(cardCount: 20) == 100)
        expect(VocabularyTestQuestionSelector.recentReviewLogLimit(cardCount: 400) == 1_000)
    }

    private static func testNewCardsRankBeforeReviewedCards() {
        let deck = VocabularyDeck(title: "Test")
        let newCard = makeCard(deckID: deck.id, term: "new")
        let reviewedCard = makeCard(deckID: deck.id, term: "reviewed")
        let reviewedState = makeState(deckID: deck.id, cardID: reviewedCard.id, dueDate: .now)

        let selected = VocabularyTestQuestionSelector.questions(
            deck: deck,
            deckCards: [reviewedCard, newCard],
            states: [reviewedState],
            recentLogs: [],
            limit: 2
        )

        expect(selected.map(\.term) == ["new", "reviewed"])
    }

    private static func testLatestAgainLogRanksAheadOfLatestGoodLog() {
        let deck = VocabularyDeck(title: "Test")
        let now = Date()
        let wrong = makeCard(deckID: deck.id, term: "wrong")
        let good = makeCard(deckID: deck.id, term: "good")
        let wrongState = makeState(deckID: deck.id, cardID: wrong.id, dueDate: now.addingTimeInterval(3_600))
        let goodState = makeState(deckID: deck.id, cardID: good.id, dueDate: now.addingTimeInterval(3_600))

        let selected = VocabularyTestQuestionSelector.questions(
            deck: deck,
            deckCards: [good, wrong],
            states: [goodState, wrongState],
            recentLogs: [
                makeLog(deckID: deck.id, cardID: wrong.id, rating: .good, reviewedAt: now.addingTimeInterval(-60)),
                makeLog(deckID: deck.id, cardID: wrong.id, rating: .again, reviewedAt: now),
                makeLog(deckID: deck.id, cardID: good.id, rating: .good, reviewedAt: now)
            ],
            limit: 2
        )

        expect(selected.first?.id == wrong.id)
    }

    private static func testPriorityUsesLatestReviewLog() {
        let deck = VocabularyDeck(title: "Test")
        let now = Date()
        let card = makeCard(deckID: deck.id, term: "latest")
        let state = makeState(deckID: deck.id, cardID: card.id, dueDate: now.addingTimeInterval(3_600))
        let priorities = VocabularyTestQuestionPriority(
            deck: deck,
            states: [state],
            recentLogs: [
                makeLog(deckID: deck.id, cardID: card.id, rating: .again, reviewedAt: now.addingTimeInterval(-120)),
                makeLog(deckID: deck.id, cardID: card.id, rating: .good, reviewedAt: now)
            ]
        )
        let olderAgainPriority = VocabularyTestQuestionPriority(
            deck: deck,
            states: [state],
            recentLogs: [
                makeLog(deckID: deck.id, cardID: card.id, rating: .again, reviewedAt: now.addingTimeInterval(-120))
            ]
        )

        expect(olderAgainPriority.priority(for: card, now: now) > priorities.priority(for: card, now: now))
    }

    private static func testRandomQuestionsUseShuffledOrderAndLimit() {
        let deckID = UUID()
        let cards = [
            makeCard(deckID: deckID, term: "first"),
            makeCard(deckID: deckID, term: "second"),
            makeCard(deckID: deckID, term: "third")
        ]

        let selected = VocabularyTestQuestionSelector.randomQuestions(
            from: cards,
            limit: 2,
            shuffle: { Array($0.reversed()) }
        )

        expect(selected.map(\.term) == ["third", "second"])
        expect(VocabularyTestQuestionSelector.randomQuestions(from: cards, limit: 0).isEmpty)
        expect(VocabularyTestQuestionSelector.randomQuestions(from: [], limit: 2).isEmpty)
    }

    private static func testCustomQuestionsKeepOnlySelectedCardsInDeckOrder() {
        let deckID = UUID()
        let cards = [
            makeCard(deckID: deckID, term: "first"),
            makeCard(deckID: deckID, term: "second"),
            makeCard(deckID: deckID, term: "third")
        ]

        let selected = VocabularyTestQuestionSelector.customQuestions(
            from: cards,
            selectedCardIDs: [cards[0].id, cards[2].id]
        )

        expect(selected.map(\.term) == ["first", "third"])
    }

    private static func testAnsweringActionTitles() {
        expect(VocabularyAnsweringActionTitle.title(
            isExam: false,
            isLastInBatch: false,
            isLastBatch: false
        ) == "下一题")
        expect(VocabularyAnsweringActionTitle.title(
            isExam: false,
            isLastInBatch: true,
            isLastBatch: true
        ) == "提交答卷")
        expect(VocabularyAnsweringActionTitle.title(
            isExam: true,
            isLastInBatch: true,
            isLastBatch: false
        ) == "提交并继续")
        expect(VocabularyAnsweringActionTitle.title(
            isExam: true,
            isLastInBatch: true,
            isLastBatch: true
        ) == "提交全卷")
    }

    private static func makeCard(deckID: UUID, term: String) -> VocabularyCard {
        VocabularyCard(deckID: deckID, term: term, definition: "\(term)-definition")
    }

    private static func makeState(deckID: UUID, cardID: UUID, dueDate: Date) -> VocabularyMemoryState {
        VocabularyMemoryState(
            deckID: deckID,
            cardID: cardID,
            direction: .definitionToTerm,
            stage: .review,
            dueDate: dueDate,
            lastReviewDate: dueDate,
            stability: 1,
            difficulty: 1,
            lapseCount: 0
        )
    }

    private static func makeLog(
        deckID: UUID,
        cardID: UUID,
        rating: VocabularyReviewRating,
        reviewedAt: Date
    ) -> VocabularyReviewLog {
        VocabularyReviewLog(
            cardID: cardID,
            deckID: deckID,
            direction: .definitionToTerm,
            rating: rating,
            responseKind: "test",
            duration: 1,
            reviewedAt: reviewedAt,
            previousStability: 1,
            resultingStability: 1
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
