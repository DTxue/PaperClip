import Foundation

enum VocabularyFlashcardSwipeDecision: Equatable {
    case ignore
    case reset
    case rate(VocabularyReviewRating)

    static func make(
        translationWidth: Double,
        translationHeight: Double,
        predictedEndTranslationWidth: Double,
        isRevealed: Bool,
        threshold: Double = 120
    ) -> VocabularyFlashcardSwipeDecision {
        let isHorizontalDrag = abs(translationWidth) >= abs(translationHeight)
        guard isHorizontalDrag else { return .ignore }
        guard isRevealed else { return .reset }

        let projectedWidth = abs(predictedEndTranslationWidth) > abs(translationWidth)
            ? predictedEndTranslationWidth
            : translationWidth
        guard abs(projectedWidth) >= threshold else { return .reset }
        return .rate(projectedWidth < 0 ? .again : .good)
    }
}

struct VocabularyFlashcardSwipePresentation: Equatable {
    let width: Double

    var cardScale: Double {
        1 - min(abs(width) / 1_500, 0.06)
    }

    var colorProgress: Double {
        min(abs(width) / 180, 1)
    }

    var tintOpacity: Double {
        colorProgress * 0.18
    }

    var borderOpacity: Double {
        colorProgress > 0 ? 0.35 + colorProgress * 0.45 : 0.2
    }

    var cardOpacity: Double {
        let fadeDistance = max(0, abs(width) - 120)
        return max(0, 1 - fadeDistance / 520)
    }

    func badgeProgress(for rating: VocabularyReviewRating) -> Double {
        let distance = rating == .again ? -width : width
        return max(0, min(1, (distance - 12) / 108))
    }

    func badgeScale(for rating: VocabularyReviewRating) -> Double {
        0.9 + badgeProgress(for: rating) * 0.1
    }
}
