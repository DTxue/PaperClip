import Foundation

extension VocabularyMemoryScheduler {
    struct Result {
        let stability: Double
        let difficulty: Double
        let interval: TimeInterval
        let stage: VocabularyMemoryStage
        let scheduledDays: Double
        let learningStep: Int
        let retrievability: Double
        let reviewCount: Int
        let lapseCount: Int
        let algorithmVersion: Int
    }

    /// 基于稳定度、难度和目标保持率的间隔调度。
    ///
    /// Apple 没有提供记忆调度 API。这里的自定义实现只负责业务调度，不替代系统 UI。
    /// 公式采用可解释的遗忘曲线，并分别维护正向和反向记忆状态。
    static func review(
        state: VocabularyMemoryState,
        rating: VocabularyReviewRating,
        desiredRetention: Double,
        parameters: [Double] = VocabularySchedulingCore.defaultParameters,
        fuzzFactor: Double = 0.5,
        now: Date = .now
    ) -> Result {
        let elapsedDays = VocabularyMemoryRetrievability.elapsedDays(
            from: state.lastReviewDate,
            to: now
        )
        let inferredScheduledDays: Double
        if state.scheduledDays > 0 {
            inferredScheduledDays = state.scheduledDays
        } else if let lastReviewDate = state.lastReviewDate {
            inferredScheduledDays = max(0, state.dueDate.timeIntervalSince(lastReviewDate) / 86_400)
        } else {
            inferredScheduledDays = 0
        }
        let output = VocabularySchedulingCore.calculate(
            VocabularyScheduleInput(
                stability: state.stability,
                difficulty: state.difficulty,
                elapsedDays: elapsedDays,
                scheduledDays: inferredScheduledDays,
                learningStep: state.learningStep,
                reviewCount: state.reviewCount,
                lapseCount: state.lapseCount,
                stage: state.stage,
                rating: rating.rawValue,
                desiredRetention: desiredRetention,
                fuzzFactor: fuzzFactor,
                algorithmVersion: state.algorithmVersion
            ),
            parameters: parameters
        )
        return Result(
            stability: output.stability,
            difficulty: output.difficulty,
            interval: output.interval,
            stage: VocabularyMemoryStage(rawValue: output.stage) ?? .review,
            scheduledDays: output.scheduledDays,
            learningStep: output.learningStep,
            retrievability: output.retrievability,
            reviewCount: output.reviewCount,
            lapseCount: output.lapseCount,
            algorithmVersion: output.algorithmVersion
        )
    }

    static func currentRetrievability(
        state: VocabularyMemoryState,
        now: Date = .now,
        parameters: [Double] = VocabularySchedulingCore.defaultParameters
    ) -> Double {
        VocabularyMemoryRetrievability.current(state: state, now: now, parameters: parameters)
    }

    static func currentRetrievability(
        state: VocabularyMemoryState,
        deck: VocabularyDeck,
        now: Date = .now
    ) -> Double {
        VocabularyMemoryRetrievability.current(state: state, deck: deck, now: now)
    }
}
