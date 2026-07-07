import Foundation

extension VocabularySchedulingCore {
    static func reviewStageTransition(
        rating: Int,
        memory: (stability: Double, difficulty: Double),
        oldStability: Double,
        oldDifficulty: Double,
        elapsedDays: Double,
        input: VocabularyScheduleInput,
        parameters: [Double],
        baseLapseCount: Int
    ) -> VocabularyScheduleTransition {
        if rating == 1 {
            let nextLapseCount = baseLapseCount + 1
            if let step = learningStepOutcome(
                steps: relearningSteps,
                currentStep: 0,
                rating: rating,
                enteringRelearning: true
            ) {
                return stepTransition(
                    stage: "relearning",
                    step: step,
                    lapseCount: nextLapseCount
                )
            }
            return reviewTransition(
                stability: memory.stability,
                input: input,
                elapsedDays: elapsedDays,
                parameters: parameters,
                lapseCount: nextLapseCount
            )
        }

        return reviewTransition(
            scheduledDays: orderedReviewInterval(
                selectedRating: rating,
                stability: oldStability,
                difficulty: oldDifficulty,
                elapsedDays: elapsedDays,
                desiredRetention: input.desiredRetention,
                maximumIntervalDays: input.maximumIntervalDays,
                fuzzFactor: input.fuzzFactor,
                parameters: parameters
            ),
            lapseCount: baseLapseCount
        )
    }

    static func reviewTransition(
        scheduledDays: Double,
        lapseCount: Int
    ) -> VocabularyScheduleTransition {
        VocabularyScheduleTransition(
            stage: "review",
            learningStep: 0,
            scheduledDays: scheduledDays,
            interval: scheduledDays * secondsPerDay,
            lapseCount: lapseCount
        )
    }

    static func reviewTransition(
        stability: Double,
        input: VocabularyScheduleInput,
        elapsedDays: Double,
        parameters: [Double],
        lapseCount: Int
    ) -> VocabularyScheduleTransition {
        reviewTransition(
            scheduledDays: nextIntervalDays(
                stability: stability,
                elapsedDays: elapsedDays,
                desiredRetention: input.desiredRetention,
                maximumIntervalDays: input.maximumIntervalDays,
                fuzzFactor: input.fuzzFactor,
                parameters: parameters
            ),
            lapseCount: lapseCount
        )
    }
}
