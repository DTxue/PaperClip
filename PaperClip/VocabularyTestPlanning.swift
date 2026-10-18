import Foundation

struct VocabularyTestSessionPlan {
    let mode: VocabularyTestMode
    let batches: [VocabularyTestBatch]
    let questionCount: Int
}

enum VocabularyTestSessionPlanner {
    static func makePlan(
        deck: VocabularyDeck,
        deckCards: [VocabularyCard],
        states: [VocabularyMemoryState],
        recentLogs: [VocabularyReviewLog],
        mode: VocabularyTestMode,
        requestedQuestionCount: Int,
        selectionStrategy: VocabularyTestQuestionSelectionStrategy
    ) -> VocabularyTestSessionPlan {
        let maximumQuestionCount = VocabularyTestQuestionCount.clamped(deckCards.count)
        let selectedCards: [VocabularyCard]
        let questionCount: Int
        switch selectionStrategy {
        case .prioritized:
            questionCount = VocabularyTestSessionQuestionCountPolicy.standard.resolvedQuestionCount(
                requestedQuestionCount: requestedQuestionCount,
                maximumQuestionCount: maximumQuestionCount,
                mode: mode
            )
            selectedCards = VocabularyTestQuestionSelector.questions(
                deck: deck,
                deckCards: deckCards,
                states: states,
                recentLogs: recentLogs,
                limit: questionCount
            )
        case .random:
            questionCount = VocabularyTestSessionQuestionCountPolicy.englishDefinitionRandom.resolvedQuestionCount(
                requestedQuestionCount: requestedQuestionCount,
                maximumQuestionCount: maximumQuestionCount,
                mode: mode
            )
            selectedCards = VocabularyTestQuestionSelector.randomQuestions(
                from: deckCards,
                limit: questionCount
            )
        case .randomStandard:
            questionCount = VocabularyTestSessionQuestionCountPolicy.standard.resolvedQuestionCount(
                requestedQuestionCount: requestedQuestionCount,
                maximumQuestionCount: maximumQuestionCount,
                mode: mode
            )
            selectedCards = VocabularyTestQuestionSelector.randomQuestions(
                from: deckCards,
                limit: questionCount
            )
        case let .orderedRange(startQuestion, endQuestion):
            selectedCards = VocabularyTestQuestionSelector.orderedQuestions(
                from: deckCards,
                startQuestion: startQuestion,
                endQuestion: endQuestion
            )
            questionCount = selectedCards.count
        case let .custom(cardIDs):
            selectedCards = VocabularyTestQuestionSelector.customQuestions(
                from: deckCards,
                selectedCardIDs: cardIDs
            )
            questionCount = VocabularyTestSessionQuestionCountPolicy.englishDefinitionCustom.resolvedQuestionCount(
                requestedQuestionCount: requestedQuestionCount,
                maximumQuestionCount: maximumQuestionCount,
                customSelectionCount: selectedCards.count,
                mode: mode
            )
        }
        return VocabularyTestSessionPlan(
            mode: mode,
            batches: selectedCards.isEmpty ? [] : [
                VocabularyTestBatch(id: 0, startIndex: 0, cards: selectedCards)
            ],
            questionCount: questionCount
        )
    }
}
