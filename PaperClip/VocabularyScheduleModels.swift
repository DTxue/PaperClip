import Foundation

struct VocabularyScheduleInput {
    let stability: Double
    let difficulty: Double
    let elapsedDays: Double
    let scheduledDays: Double
    let learningStep: Int
    let reviewCount: Int
    let lapseCount: Int
    let stage: String
    let rating: Int
    let desiredRetention: Double
    let maximumIntervalDays: Double
    let fuzzFactor: Double
    let algorithmVersion: Int

    init(
        stability: Double,
        difficulty: Double,
        elapsedDays: Double,
        scheduledDays: Double = 0,
        learningStep: Int = 0,
        reviewCount: Int = 0,
        lapseCount: Int = 0,
        stage: String = "new",
        rating: Int,
        desiredRetention: Double,
        maximumIntervalDays: Double = 36_500,
        fuzzFactor: Double = 0.5,
        algorithmVersion: Int = 6
    ) {
        self.stability = stability
        self.difficulty = difficulty
        self.elapsedDays = elapsedDays
        self.scheduledDays = scheduledDays
        self.learningStep = learningStep
        self.reviewCount = reviewCount
        self.lapseCount = lapseCount
        self.stage = stage
        self.rating = rating
        self.desiredRetention = desiredRetention
        self.maximumIntervalDays = maximumIntervalDays
        self.fuzzFactor = fuzzFactor
        self.algorithmVersion = algorithmVersion
    }
}

struct VocabularyScheduleOutput {
    let stability: Double
    let difficulty: Double
    let interval: TimeInterval
    let scheduledDays: Double
    let learningStep: Int
    let stage: String
    let retrievability: Double
    let reviewCount: Int
    let lapseCount: Int
    let algorithmVersion: Int
}
