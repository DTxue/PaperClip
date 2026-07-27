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
        requestedQuestionCount: Int
    ) -> VocabularyTestSessionPlan {
        let maximumQuestionCount = VocabularyTestQuestionCount.clamped(deckCards.count)
        let questionCount = mode.resolvedQuestionCount(
            requestedQuestionCount: requestedQuestionCount,
            maximumQuestionCount: maximumQuestionCount
        )
        let selectedCards = VocabularyTestQuestionSelector.questions(
            deck: deck,
            deckCards: deckCards,
            states: states,
            recentLogs: recentLogs,
            limit: mode == .exam ? deckCards.count : questionCount
        )
        return VocabularyTestSessionPlan(
            mode: mode,
            batches: VocabularyTestBatchBuilder.makeBatches(
                from: selectedCards,
                batchSize: questionCount
            ),
            questionCount: questionCount
        )
    }
}
