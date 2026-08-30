import SwiftUI

extension VocabularyFlashcardView {
    func performRating(_ rating: VocabularyReviewRating, cardID: UUID) {
        guard isRevealed, !isAnimatingSwipe, current?.id == cardID else { return }
        isAnimatingSwipe = true
        let targetX: CGFloat = rating.swipeDirection * 900
        let targetY = swipeOffset.height

        if reduceMotion {
            completeRating(rating, cardID: cardID)
        } else {
            withAnimation(.snappy(duration: 0.18), completionCriteria: .logicallyComplete) {
                swipeOffset = CGSize(width: targetX, height: targetY)
            } completion: {
                completeRating(rating, cardID: cardID)
            }
        }
    }

    func prompt(for card: VocabularyCard) -> String {
        VocabularyStudySessionItemFactory.prompt(for: card, direction: direction)
    }

    func answer(for card: VocabularyCard) -> String {
        VocabularyStudySessionItemFactory.answer(for: card, direction: direction)
    }

    func revealCard() {
        guard !isAnimatingSwipe else { return }
        withAnimation(.snappy) {
            isRevealed.toggle()
        }
    }

    func completeRating(
        _ rating: VocabularyReviewRating,
        cardID: UUID
    ) {
        guard let card = current, card.id == cardID else {
            resetSwipeState()
            return
        }

        applyRatingProgress(rating, card: card)
        advanceAfterRating(rating)
    }

    func resetSwipeState() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            swipeOffset = .zero
            cardEntryOffset = 0
            cardEntryOpacity = 1
        }
        isAnimatingSwipe = false
    }

}
