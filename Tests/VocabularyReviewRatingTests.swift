import Foundation

func assert(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fatalError(message)
    }
}

@main
struct VocabularyReviewRatingTests {
    static func main() {
        assert(!VocabularyReviewRating.again.isPassingRecall, "again should not pass recall")
        assert(VocabularyReviewRating.hard.isPassingRecall, "hard should pass recall")
        assert(VocabularyReviewRating.good.isPassingRecall, "good should pass recall")
        assert(VocabularyReviewRating.easy.isPassingRecall, "easy should pass recall")

        assert(VocabularyReviewRating.again.swipeDirection == -1, "again swipes left")
        assert(VocabularyReviewRating.hard.swipeDirection == -1, "hard exits left")
        assert(VocabularyReviewRating.good.swipeDirection == 1, "good exits right")
        assert(VocabularyReviewRating.easy.swipeDirection == 1, "easy exits right")

        assert(!VocabularyReviewRating.again.usesProminentButton, "again uses secondary button")
        assert(!VocabularyReviewRating.hard.usesProminentButton, "hard uses secondary button")
        assert(VocabularyReviewRating.good.usesProminentButton, "good uses prominent button")
        assert(!VocabularyReviewRating.easy.usesProminentButton, "easy uses secondary button")

        assert(
            VocabularyReviewLog.masteryPropertiesToFetch.count == 5,
            "mastery fetch should include card, direction, rating, response kind and review date"
        )
        assert(
            VocabularyReviewLog.testSelectionPropertiesToFetch.count == 3,
            "test selection fetch should include only card, rating and review date"
        )

        assert(
            VocabularyFlashcardSwipeDecision.make(
                translationWidth: -130,
                translationHeight: 10,
                predictedEndTranslationWidth: -130,
                isRevealed: true
            ) == .rate(.again),
            "revealed left swipe rates again"
        )
        assert(
            VocabularyFlashcardSwipeDecision.make(
                translationWidth: 130,
                translationHeight: 10,
                predictedEndTranslationWidth: 130,
                isRevealed: true
            ) == .rate(.good),
            "revealed right swipe rates good"
        )
        assert(
            VocabularyFlashcardSwipeDecision.make(
                translationWidth: 80,
                translationHeight: 10,
                predictedEndTranslationWidth: 150,
                isRevealed: true
            ) == .rate(.good),
            "predicted right swipe can rate good"
        )
        assert(
            VocabularyFlashcardSwipeDecision.make(
                translationWidth: 130,
                translationHeight: 10,
                predictedEndTranslationWidth: 130,
                isRevealed: false
            ) == .reset,
            "hidden card horizontal swipe resets"
        )
        assert(
            VocabularyFlashcardSwipeDecision.make(
                translationWidth: 40,
                translationHeight: 100,
                predictedEndTranslationWidth: 180,
                isRevealed: true
            ) == .ignore,
            "vertical drag is ignored"
        )
        assert(
            VocabularyFlashcardSwipeDecision.make(
                translationWidth: 80,
                translationHeight: 10,
                predictedEndTranslationWidth: 80,
                isRevealed: true
            ) == .reset,
            "short horizontal drag resets"
        )

        let horizontalDrag = VocabularyFlashcardDragSupport.updatedState(
            from: .inactive,
            translationWidth: 90,
            translationHeight: 20
        )
        assert(horizontalDrag.axis == .horizontal, "horizontal drag should lock the swipe axis")
        assert(horizontalDrag.translation.width == 90, "horizontal drag should move the card")
        assertAlmostEqual(horizontalDrag.translation.height, 1.6, "vertical movement should be damped")

        let verticalDrag = VocabularyFlashcardDragSupport.updatedState(
            from: .inactive,
            translationWidth: 20,
            translationHeight: 90
        )
        assert(verticalDrag.axis == .vertical, "vertical drag should lock the vertical axis")
        assert(verticalDrag.translation == .zero, "vertical drag should not move the card")

        let neutral = VocabularyFlashcardSwipePresentation(width: 0)
        assertAlmostEqual(neutral.cardScale, 1, "neutral card keeps full scale")
        assertAlmostEqual(neutral.colorProgress, 0, "neutral card has no color progress")
        assertAlmostEqual(neutral.cardOpacity, 1, "neutral card keeps full opacity")
        assertAlmostEqual(neutral.badgeProgress(for: .good), 0, "neutral good badge is hidden")

        let right = VocabularyFlashcardSwipePresentation(width: 120)
        assertAlmostEqual(right.badgeProgress(for: .good), 1, "right swipe fully reveals good badge")
        assertAlmostEqual(right.badgeProgress(for: .again), 0, "right swipe hides again badge")
        assertAlmostEqual(right.badgeScale(for: .good), 1, "fully revealed badge reaches full scale")

        let far = VocabularyFlashcardSwipePresentation(width: 1_500)
        assertAlmostEqual(far.cardScale, 0.94, "card scale is capped")
        assertAlmostEqual(far.colorProgress, 1, "color progress is capped")
        assertAlmostEqual(far.cardOpacity, 0, "far swiped card fades out")

        print("VocabularyReviewRatingTests: 27 passed")
    }

    private static func assertAlmostEqual(
        _ actual: Double,
        _ expected: Double,
        _ message: String,
        tolerance: Double = 0.000_001
    ) {
        assert(abs(actual - expected) <= tolerance, message)
    }
}
