import Foundation

struct VocabularyWeightedMasteryResult {
    let flashcardAccuracy: Double?
    let studyAccuracy: Double?
    let quizAccuracy: Double?
    let trainingMastery: Double
    let quizMastery: Double?
    let weightedMastery: Double

    var activeDimensionCount: Int {
        [flashcardAccuracy, studyAccuracy, quizAccuracy].compactMap { $0 }.count
    }
}

enum VocabularyWeightedMasteryCalculator {
    private static let flashcardWeight = 0.15
    private static let studyWeight = 0.25
    private static let correctThreshold = 3
    private static let quizEvidenceCountForFullCredit = 5

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
        let flashcard = accuracy(
            from: logs,
            matching: { $0.responseKind == "闪卡" },
            limit: recentCount
        )
        let study = accuracy(
            from: logs,
            matching: { $0.responseKind == "拼句" },
            limit: recentCount
        )
        let quiz = accuracy(
            from: logs,
            matching: { $0.responseKind.hasPrefix("测验") },
            limit: recentCount
        )
        let trainingMastery = trainingScore(
            flashcard: flashcard?.accuracy,
            study: study?.accuracy
        )
        let quizMastery = quizScore(quiz)

        return VocabularyWeightedMasteryResult(
            flashcardAccuracy: flashcard?.accuracy,
            studyAccuracy: study?.accuracy,
            quizAccuracy: quiz?.accuracy,
            trainingMastery: trainingMastery,
            quizMastery: quizMastery,
            weightedMastery: max(trainingMastery, quizMastery ?? 0)
        )
    }

    private static func accuracy(
        from sorted: [VocabularyReviewLog],
        matching predicate: (VocabularyReviewLog) -> Bool,
        limit: Int
    ) -> AccuracySnapshot? {
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
        return AccuracySnapshot(
            accuracy: Double(correctCount) / Double(matchedCount),
            count: matchedCount
        )
    }

    private static func trainingScore(
        flashcard: Double?,
        study: Double?,
    ) -> Double {
        var score = 0.0
        if let value = flashcard { score += flashcardWeight * value }
        if let value = study { score += studyWeight * value }
        return min(score, flashcardWeight + studyWeight)
    }

    private static func quizScore(_ quiz: AccuracySnapshot?) -> Double? {
        guard let quiz else { return nil }
        let accuracyScore = pow(quiz.accuracy, 1.5)
        let evidenceScore = min(
            Double(quiz.count) / Double(quizEvidenceCountForFullCredit),
            1
        )
        return accuracyScore * evidenceScore
    }
}

private struct AccuracySnapshot {
    let accuracy: Double
    let count: Int
}
