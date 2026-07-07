import SwiftUI

extension VocabularyFlashcardView {
    private var swipePresentation: VocabularyFlashcardSwipePresentation {
        VocabularyFlashcardSwipePresentation(width: cardOffset.width)
    }

    func swipeChoiceBadge(_ rating: VocabularyReviewRating) -> some View {
        return Label(rating.title, systemImage: rating.systemImage)
            .font(.headline)
            .foregroundStyle(rating.tint)
            .opacity(swipePresentation.badgeProgress(for: rating))
            .scaleEffect(swipePresentation.badgeScale(for: rating))
    }

    @ViewBuilder
    func ratingButton(_ rating: VocabularyReviewRating, cardID: UUID) -> some View {
        if rating.usesProminentButton {
            Button(rating.title, systemImage: rating.systemImage) {
                performRating(rating, cardID: cardID)
            }
            .buttonStyle(.borderedProminent)
            .tint(rating.tint)
            .disabled(!isRevealed)
        } else {
            Button(rating.title, systemImage: rating.systemImage) {
                performRating(rating, cardID: cardID)
            }
            .buttonStyle(.bordered)
            .tint(rating.tint)
            .disabled(!isRevealed)
        }
    }

    var swipeCardScale: CGFloat {
        CGFloat(swipePresentation.cardScale)
    }

    var swipeColorProgress: CGFloat {
        CGFloat(swipePresentation.colorProgress)
    }

    var swipeChoiceColor: Color {
        cardOffset.width < 0 ? .red : .green
    }

    var swipeCardTint: Color {
        guard swipeColorProgress > 0 else { return .clear }
        return swipeChoiceColor.opacity(swipePresentation.tintOpacity)
    }

    var swipeCardBorderColor: Color {
        guard swipeColorProgress > 0 else { return Color.secondary.opacity(0.2) }
        return swipeChoiceColor.opacity(swipePresentation.borderOpacity)
    }

    var swipeCardOpacity: Double {
        swipePresentation.cardOpacity
    }
}
