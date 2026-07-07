import Foundation

struct VocabularyScheduleTransition {
    let stage: String
    let learningStep: Int
    let scheduledDays: Double
    let interval: TimeInterval
    let lapseCount: Int
}

extension VocabularySchedulingCore {
    static func transition(
        oldStage: String,
        input: VocabularyScheduleInput,
        rating: Int,
        memory: (stability: Double, difficulty: Double),
        oldStability: Double,
        oldDifficulty: Double,
        elapsedDays: Double,
        parameters: [Double]
    ) -> VocabularyScheduleTransition {
        let baseLapseCount = max(0, input.lapseCount)

        if let plan = learningStagePlan(oldStage: oldStage, input: input) {
            return learningTransition(
                stage: plan.stage,
                steps: plan.steps,
                currentStep: plan.currentStep,
                rating: rating,
                memory: memory,
                input: input,
                elapsedDays: elapsedDays,
                parameters: parameters,
                lapseCount: baseLapseCount
            )
        }

        return reviewStageTransition(
            rating: rating,
            memory: memory,
            oldStability: oldStability,
            oldDifficulty: oldDifficulty,
            elapsedDays: elapsedDays,
            input: input,
            parameters: parameters,
            baseLapseCount: baseLapseCount
        )
    }

    private static func learningTransition(
        stage: String,
        steps: [Int],
        currentStep: Int,
        rating: Int,
        memory: (stability: Double, difficulty: Double),
        input: VocabularyScheduleInput,
        elapsedDays: Double,
        parameters: [Double],
        lapseCount: Int
    ) -> VocabularyScheduleTransition {
        guard let step = learningStepOutcome(
            steps: steps,
            currentStep: currentStep,
            rating: rating
        ) else {
            return reviewTransition(
                stability: memory.stability,
                input: input,
                elapsedDays: elapsedDays,
                parameters: parameters,
                lapseCount: lapseCount
            )
        }
        return stepTransition(stage: stage, step: step, lapseCount: lapseCount)
    }

    static func stepTransition(
        stage: String,
        step: (minutes: Int, nextStep: Int),
        lapseCount: Int
    ) -> VocabularyScheduleTransition {
        VocabularyScheduleTransition(
            stage: stage,
            learningStep: step.nextStep,
            scheduledDays: 0,
            interval: Double(step.minutes) * 60,
            lapseCount: lapseCount
        )
    }
}
