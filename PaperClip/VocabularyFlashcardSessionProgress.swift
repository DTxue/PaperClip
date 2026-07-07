import SwiftUI

extension VocabularyFlashcardView {
    func applyRatingProgress(_ rating: VocabularyReviewRating, card: VocabularyCard) {
        if rating == .again {
            nextRound.append(card)
            roundLearningCount += 1
        } else {
            completedCardIDs.insert(card.id)
            roundKnownCount += 1
        }
    }

    func advanceAfterRating(_ rating: VocabularyReviewRating) {
        let nextIndex = index + 1
        let hasNextCard = queue.indices.contains(nextIndex)
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            swipeOffset = .zero
            cardEntryOffset = hasNextCard && !reduceMotion ? -rating.swipeDirection * 56 : 0
            cardEntryOpacity = hasNextCard && !reduceMotion ? 0 : 1
            isRevealed = false
            index = nextIndex
        }

        guard hasNextCard else {
            isAnimatingSwipe = false
            finishRound()
            return
        }

        if reduceMotion {
            markNextCardStarted()
        } else {
            withAnimation(.snappy(duration: 0.22), completionCriteria: .logicallyComplete) {
                cardEntryOffset = 0
                cardEntryOpacity = 1
            } completion: {
                markNextCardStarted()
            }
        }
    }

    func markNextCardStarted() {
        isAnimatingSwipe = false
        startedAt = .now
    }
}
