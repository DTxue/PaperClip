import SwiftUI

extension VocabularyFlashcardView {
    func swipeGesture(cardID: UUID) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .updating($activeDrag) { value, state, _ in
                guard !isAnimatingSwipe else { return }
                state = VocabularyFlashcardDragSupport.updatedState(
                    from: state,
                    translationWidth: value.translation.width,
                    translationHeight: value.translation.height
                )
            }
            .onEnded { value in
                guard !isAnimatingSwipe else { return }

                let translation = value.translation
                let releaseOffset = CGSize(
                    width: translation.width,
                    height: translation.height * 0.08
                )
                let decision = VocabularyFlashcardSwipeDecision.make(
                    translationWidth: translation.width,
                    translationHeight: translation.height,
                    predictedEndTranslationWidth: value.predictedEndTranslation.width,
                    isRevealed: isRevealed
                )

                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    swipeOffset = decision == .ignore ? .zero : releaseOffset
                }

                switch decision {
                case .ignore:
                    return
                case .reset:
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        swipeOffset = .zero
                    }
                case .rate(let rating):
                    performRating(rating, cardID: cardID)
                }
            }
    }
}
