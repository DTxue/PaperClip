import Foundation

struct VocabularyMemoryReviewSnapshot {
    let stability: Double
    let difficulty: Double
    let stage: String
    let elapsedDays: Double
}

extension VocabularyMemoryState {
    func reviewSnapshot(elapsedDays: Double) -> VocabularyMemoryReviewSnapshot {
        VocabularyMemoryReviewSnapshot(
            stability: stability,
            difficulty: difficulty,
            stage: stage,
            elapsedDays: elapsedDays
        )
    }

    func apply(_ result: VocabularyMemoryScheduler.Result, reviewedAt now: Date) {
        stability = result.stability
        difficulty = result.difficulty
        retrievability = 1
        dueDate = now.addingTimeInterval(result.interval)
        lastReviewDate = now
        stage = result.stage.rawValue
        scheduledDays = result.scheduledDays
        learningStep = result.learningStep
        algorithmVersion = result.algorithmVersion
        reviewCount = result.reviewCount
        lapseCount = result.lapseCount
    }
}

extension VocabularyReviewLog {
    convenience init(
        card: VocabularyCard,
        deck: VocabularyDeck,
        direction: VocabularyDirection,
        rating: VocabularyReviewRating,
        responseKind: String,
        duration: TimeInterval,
        previous: VocabularyMemoryReviewSnapshot,
        result: VocabularyMemoryScheduler.Result
    ) {
        self.init(
            cardID: card.id,
            deckID: deck.id,
            direction: direction,
            rating: rating,
            responseKind: responseKind,
            duration: duration,
            previousStability: previous.stability,
            resultingStability: result.stability,
            previousDifficulty: previous.difficulty,
            resultingDifficulty: result.difficulty,
            retrievability: result.retrievability,
            elapsedDays: previous.elapsedDays,
            scheduledDays: result.scheduledDays,
            reviewState: previous.stage,
            algorithmVersion: result.algorithmVersion
        )
    }
}
