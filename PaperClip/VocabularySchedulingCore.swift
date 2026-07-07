import Foundation

/// 标准 FSRS-6 调度核心。
///
/// Apple 没有提供记忆调度 API。公式、21 个默认参数和学习阶段转换与
/// Open Spaced Repetition 的 FSRS-6 参考实现保持一致；项目层仅增加了
/// 可复现的间隔扰动，以分散同日到期卡片。
enum VocabularySchedulingCore {
    static let algorithmVersion = 6

    /// Canonical FSRS-6.0 default parameters.
    static let defaultParameters: [Double] = [
        0.212, 1.2931, 2.3065, 8.2956, 6.4133,
        0.8334, 3.0194, 0.001, 1.8722, 0.1666,
        0.796, 1.4835, 0.0614, 0.2629, 1.6483,
        0.6014, 1.8729, 0.5425, 0.0912, 0.0658,
        0.1542
    ]

    static let learningSteps = [1, 10]
    static let relearningSteps = [10]
    static let minimumStability = 0.001
    static let secondsPerDay = 86_400.0

    static func calculate(
        _ input: VocabularyScheduleInput,
        parameters rawParameters: [Double] = defaultParameters
    ) -> VocabularyScheduleOutput {
        let parameters = validatedParameters(rawParameters)
        let rating = min(4, max(1, input.rating))
        let oldStage = normalizedStage(input)
        let elapsedDays = max(0, input.elapsedDays)
        let oldStability = oldStage == "new" ? 0 : max(minimumStability, input.stability)
        let oldDifficulty = oldStage == "new" ? 0 : clamp(input.difficulty, 1, 10)
        let retrievability = oldStage == "new"
            ? 0
            : forgettingCurve(elapsedDays: elapsedDays, stability: oldStability, parameters: parameters)

        let memory = nextMemoryState(
            stability: oldStability,
            difficulty: oldDifficulty,
            elapsedDays: elapsedDays,
            rating: rating,
            parameters: parameters
        )

        let transition = transition(
            oldStage: oldStage,
            input: input,
            rating: rating,
            memory: memory,
            oldStability: oldStability,
            oldDifficulty: oldDifficulty,
            elapsedDays: elapsedDays,
            parameters: parameters
        )

        return VocabularyScheduleOutput(
            stability: memory.stability,
            difficulty: memory.difficulty,
            interval: transition.interval,
            scheduledDays: transition.scheduledDays,
            learningStep: transition.learningStep,
            stage: transition.stage,
            retrievability: retrievability,
            reviewCount: max(0, input.reviewCount) + 1,
            lapseCount: transition.lapseCount,
            algorithmVersion: algorithmVersion
        )
    }

    static func retrievability(
        stability: Double,
        elapsedDays: Double,
        parameters: [Double] = defaultParameters
    ) -> Double {
        guard stability > 0 else { return 0 }
        return forgettingCurve(
            elapsedDays: max(0, elapsedDays),
            stability: max(minimumStability, stability),
            parameters: validatedParameters(parameters)
        )
    }
}
