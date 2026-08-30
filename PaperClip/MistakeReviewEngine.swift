import Foundation

struct MistakeReviewUpdate: Equatable {
    let status: MistakeLearningStatus
    let correctStreak: Int
    let nextReviewAt: Date?
}

enum MistakeReviewEngine {
    static func initialReviewDate(from date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: 1, to: date) ?? date
    }

    static func update(
        after outcome: MistakeReviewOutcome,
        currentCorrectStreak: Int,
        at date: Date,
        calendar: Calendar = .current
    ) -> MistakeReviewUpdate {
        switch outcome {
        case .incorrect:
            return MistakeReviewUpdate(
                status: .learning,
                correctStreak: 0,
                nextReviewAt: calendar.date(byAdding: .day, value: 1, to: date)
            )
        case .correct:
            let streak = max(0, currentCorrectStreak) + 1
            if streak >= 3 {
                return MistakeReviewUpdate(
                    status: .mastered,
                    correctStreak: streak,
                    nextReviewAt: nil
                )
            }
            let interval = streak == 1 ? 3 : 7
            return MistakeReviewUpdate(
                status: .learning,
                correctStreak: streak,
                nextReviewAt: calendar.date(byAdding: .day, value: interval, to: date)
            )
        }
    }
}
