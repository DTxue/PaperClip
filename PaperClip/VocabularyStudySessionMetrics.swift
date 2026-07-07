import Foundation

struct VocabularyStudySessionMetrics: Equatable {
    let totalCount: Int
    let correctCount: Int

    init(totalCount: Int, correctCount: Int) {
        self.totalCount = max(totalCount, 0)
        self.correctCount = min(max(correctCount, 0), self.totalCount)
    }

    init(correctness: some Sequence<Bool>) {
        var correctCount = 0
        var totalCount = 0
        for isCorrect in correctness {
            totalCount += 1
            if isCorrect {
                correctCount += 1
            }
        }
        self.init(totalCount: totalCount, correctCount: correctCount)
    }

    static func aggregate(_ metrics: some Sequence<VocabularyStudySessionMetrics>) -> VocabularyStudySessionMetrics {
        var totalCount = 0
        var correctCount = 0
        for metric in metrics {
            totalCount += metric.totalCount
            correctCount += metric.correctCount
        }
        return VocabularyStudySessionMetrics(totalCount: totalCount, correctCount: correctCount)
    }

    var accuracy: Double {
        guard totalCount > 0 else { return 0 }
        return Double(correctCount) / Double(totalCount)
    }

    var errorRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(totalCount - correctCount) / Double(totalCount)
    }
}
