import Foundation

@main
struct VocabularySchedulingCoreTests {
    static func main() {
        expect(VocabularySchedulingCore.defaultParameters.count == 21)
        expect(VocabularySchedulingCore.algorithmVersion == 6)
        testLearningStagePlans()

        let again = newCard(rating: 1)
        let hard = newCard(rating: 2)
        let good = newCard(rating: 3)
        let easy = newCard(rating: 4)

        expect(again.stage == "learning")
        expect(again.interval == 60)
        expect(again.learningStep == 0)
        expectClose(again.stability, 0.212)
        expectClose(again.difficulty, 6.4133)

        expect(hard.stage == "learning")
        expect(hard.interval == 360)
        expectClose(hard.stability, 1.2931)
        expectClose(hard.difficulty, 5.11217071)

        expect(good.stage == "learning")
        expect(good.interval == 600)
        expect(good.learningStep == 1)
        expectClose(good.stability, 2.3065)
        expectClose(good.difficulty, 2.11810397)

        expect(easy.stage == "review")
        expect(easy.scheduledDays == 8)
        expectClose(easy.stability, 8.2956)
        expectClose(easy.difficulty, 1)

        let graduated = VocabularySchedulingCore.calculate(
            VocabularyScheduleInput(
                stability: good.stability,
                difficulty: good.difficulty,
                elapsedDays: 0,
                learningStep: good.learningStep,
                reviewCount: good.reviewCount,
                lapseCount: good.lapseCount,
                stage: good.stage,
                rating: 3,
                desiredRetention: 0.9
            )
        )
        expect(graduated.stage == "review")
        expect(graduated.scheduledDays == 2)

        let reviewHard = reviewCard(rating: 2)
        let reviewGood = reviewCard(rating: 3)
        let reviewEasy = reviewCard(rating: 4)
        expect(reviewHard.stage == "review")
        expect(reviewHard.scheduledDays < reviewGood.scheduledDays)
        expect(reviewGood.scheduledDays < reviewEasy.scheduledDays)
        expect(reviewHard.difficulty > reviewGood.difficulty)
        expect(reviewEasy.difficulty < reviewGood.difficulty)

        let forgotten = reviewCard(rating: 1)
        expect(forgotten.stage == "relearning")
        expect(forgotten.interval == 600)
        expect(forgotten.lapseCount == 3)
        expect(forgotten.stability < 10)

        let highRetention = reviewCard(rating: 3, desiredRetention: 0.97)
        let lowerRetention = reviewCard(rating: 3, desiredRetention: 0.80)
        expect(highRetention.scheduledDays < lowerRetention.scheduledDays)

        expectClose(
            VocabularySchedulingCore.retrievability(stability: 1, elapsedDays: 1),
            0.9,
            tolerance: 0.0001
        )
        expect(
            VocabularySchedulingCore.retrievability(stability: 1, elapsedDays: 10)
                < VocabularySchedulingCore.retrievability(stability: 1, elapsedDays: 1)
        )
        expectClose(
            VocabularySchedulingCore.forgettingCurve(
                elapsedDays: 1,
                stability: 1,
                parameters: VocabularySchedulingCore.defaultParameters
            ),
            0.9,
            tolerance: 0.0001
        )
        expectClose(
            VocabularySchedulingCore.retentionIntervalModifier(
                retention: 0.9,
                parameters: VocabularySchedulingCore.defaultParameters
            ),
            1
        )

        print("VocabularySchedulingCoreTests: 43 passed")
    }

    private static func testLearningStagePlans() {
        let baseInput = VocabularyScheduleInput(
            stability: 0,
            difficulty: 0,
            elapsedDays: 0,
            learningStep: -2,
            rating: 1,
            desiredRetention: 0.9
        )

        let newPlan = VocabularySchedulingCore.learningStagePlan(oldStage: "new", input: baseInput)
        expect(newPlan?.stage == "learning")
        expect(newPlan?.steps == VocabularySchedulingCore.learningSteps)
        expect(newPlan?.currentStep == 0)

        let learningPlan = VocabularySchedulingCore.learningStagePlan(oldStage: "learning", input: baseInput)
        expect(learningPlan?.stage == "learning")
        expect(learningPlan?.currentStep == 0)

        let relearningPlan = VocabularySchedulingCore.learningStagePlan(oldStage: "relearning", input: baseInput)
        expect(relearningPlan?.stage == "relearning")
        expect(relearningPlan?.steps == VocabularySchedulingCore.relearningSteps)
        expect(relearningPlan?.currentStep == 0)

        expect(VocabularySchedulingCore.learningStagePlan(oldStage: "review", input: baseInput) == nil)
    }

    private static func newCard(rating: Int) -> VocabularyScheduleOutput {
        VocabularySchedulingCore.calculate(
            VocabularyScheduleInput(
                stability: 0,
                difficulty: 0,
                elapsedDays: 0,
                rating: rating,
                desiredRetention: 0.9
            )
        )
    }

    private static func reviewCard(
        rating: Int,
        desiredRetention: Double = 0.9
    ) -> VocabularyScheduleOutput {
        VocabularySchedulingCore.calculate(
            VocabularyScheduleInput(
                stability: 10,
                difficulty: 5,
                elapsedDays: 10,
                scheduledDays: 10,
                reviewCount: 12,
                lapseCount: 2,
                stage: "review",
                rating: rating,
                desiredRetention: desiredRetention
            )
        )
    }

    private static func expectClose(
        _ lhs: Double,
        _ rhs: Double,
        tolerance: Double = 0.000_000_1,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(abs(lhs - rhs) <= tolerance, file: file, line: line)
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
