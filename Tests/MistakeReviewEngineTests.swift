import Foundation

@main
enum MistakeReviewEngineTests {
    static func main() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        expect(
            MistakeReviewEngine.initialReviewDate(from: now, calendar: calendar)
                == calendar.date(byAdding: .day, value: 1, to: now),
            "new mistakes are reviewed the next day"
        )

        let incorrect = MistakeReviewEngine.update(
            after: .incorrect,
            currentCorrectStreak: 2,
            at: now,
            calendar: calendar
        )
        expect(incorrect.status == .learning, "incorrect answers stay in learning")
        expect(incorrect.correctStreak == 0, "incorrect answers reset the streak")
        expect(
            incorrect.nextReviewAt == calendar.date(byAdding: .day, value: 1, to: now),
            "incorrect answers return tomorrow"
        )

        let firstCorrect = MistakeReviewEngine.update(
            after: .correct,
            currentCorrectStreak: 0,
            at: now,
            calendar: calendar
        )
        expect(firstCorrect.status == .learning, "first correct answer remains in learning")
        expect(firstCorrect.correctStreak == 1, "first correct answer starts the streak")
        expect(
            firstCorrect.nextReviewAt == calendar.date(byAdding: .day, value: 3, to: now),
            "first correct answer returns in three days"
        )

        let secondCorrect = MistakeReviewEngine.update(
            after: .correct,
            currentCorrectStreak: 1,
            at: now,
            calendar: calendar
        )
        expect(secondCorrect.correctStreak == 2, "second correct answer advances the streak")
        expect(
            secondCorrect.nextReviewAt == calendar.date(byAdding: .day, value: 7, to: now),
            "second correct answer returns in seven days"
        )

        let mastered = MistakeReviewEngine.update(
            after: .correct,
            currentCorrectStreak: 2,
            at: now,
            calendar: calendar
        )
        expect(mastered.status == .mastered, "third correct answer marks mastery")
        expect(mastered.correctStreak == 3, "mastery keeps the streak")
        expect(mastered.nextReviewAt == nil, "mastered mistakes leave the due queue")

        print("MistakeReviewEngineTests: 15 passed")
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError(message, file: file, line: line)
        }
    }
}
