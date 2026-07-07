import Foundation

struct VocabularyWeightedMasteryResult {
    let flashcardAccuracy: Double?
    let studyAccuracy: Double?
    let quizAccuracy: Double?
    let weightedMastery: Double

    var activeDimensionCount: Int {
        [flashcardAccuracy, studyAccuracy, quizAccuracy].compactMap { $0 }.count
    }
}

enum VocabularyWeightedMasteryCalculator {
    private static let flashcardWeight = 0.15
    private static let studyWeight = 0.25
    private static let quizWeight = 0.60
    private static let correctThreshold = 3

    static func calculate(
        logs: [VocabularyReviewLog],
        recentCount: Int = 20
    ) -> VocabularyWeightedMasteryResult {
        let sorted = logs.sorted { $0.reviewedAt > $1.reviewedAt }
        return calculate(sortedNewestFirstLogs: sorted, recentCount: recentCount)
    }

    static func calculate(
        sortedNewestFirstLogs logs: [VocabularyReviewLog],
        recentCount: Int = 20
    ) -> VocabularyWeightedMasteryResult {
        let flashcardAccuracy = accuracy(
            from: logs,
            matching: { $0.responseKind == "闪卡" },
            limit: recentCount
        )
        let studyAccuracy = accuracy(
            from: logs,
            matching: { $0.responseKind == "拼句" },
            limit: recentCount
        )
        let quizAccuracy = accuracy(
            from: logs,
            matching: { $0.responseKind.hasPrefix("测验") },
            limit: recentCount
        )

        return VocabularyWeightedMasteryResult(
            flashcardAccuracy: flashcardAccuracy,
            studyAccuracy: studyAccuracy,
            quizAccuracy: quizAccuracy,
            weightedMastery: weightedScore(
                flashcard: flashcardAccuracy,
                study: studyAccuracy,
                quiz: quizAccuracy
            )
        )
    }

    private static func accuracy(
        from sorted: [VocabularyReviewLog],
        matching predicate: (VocabularyReviewLog) -> Bool,
        limit: Int
    ) -> Double? {
        var matchedCount = 0
        var correctCount = 0

        for log in sorted where predicate(log) {
            matchedCount += 1
            if log.rating >= correctThreshold {
                correctCount += 1
            }
            if matchedCount == limit {
                break
            }
        }

        guard matchedCount > 0 else { return nil }
        return Double(correctCount) / Double(matchedCount)
    }

    private static func weightedScore(
        flashcard: Double?,
        study: Double?,
        quiz: Double?
    ) -> Double {
        var score = 0.0
        if let value = flashcard { score += flashcardWeight * value }
        if let value = study { score += studyWeight * value }
        if let value = quiz { score += quizWeight * value }
        return score
    }
}
