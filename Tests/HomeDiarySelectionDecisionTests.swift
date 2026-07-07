import Foundation

@main
struct HomeDiarySelectionDecisionTests {
    static func main() {
        testTodayDateSelectsToday()
        testExistingEntrySelectsEntryID()
        testMissingEntryIDCreatesStartOfDay()
        print("HomeDiarySelectionDecisionTests: 3 passed")
    }

    private static func testTodayDateSelectsToday() {
        let calendar = gregorianCalendar
        let now = date(year: 2026, month: 7, day: 7, hour: 9, calendar: calendar)
        let selected = date(year: 2026, month: 7, day: 7, hour: 22, calendar: calendar)
        let entryID = UUID()

        let decision = HomeDiarySelectionDecision.decision(
            for: selected,
            entryID: entryID,
            calendar: calendar,
            now: now
        )

        assert(decision == .today, "Selecting today's date should prefer the today entry")
    }

    private static func testExistingEntrySelectsEntryID() {
        let calendar = gregorianCalendar
        let now = date(year: 2026, month: 7, day: 7, hour: 9, calendar: calendar)
        let selected = date(year: 2026, month: 7, day: 3, hour: 22, calendar: calendar)
        let entryID = UUID()

        let decision = HomeDiarySelectionDecision.decision(
            for: selected,
            entryID: entryID,
            calendar: calendar,
            now: now
        )

        assert(decision == .existing(entryID), "A past date with an entry should select that entry")
    }

    private static func testMissingEntryIDCreatesStartOfDay() {
        let calendar = gregorianCalendar
        let now = date(year: 2026, month: 7, day: 7, hour: 9, calendar: calendar)
        let selected = date(year: 2026, month: 7, day: 3, hour: 22, calendar: calendar)
        let expected = date(year: 2026, month: 7, day: 3, hour: 0, calendar: calendar)

        let decision = HomeDiarySelectionDecision.decision(
            for: selected,
            entryID: nil,
            calendar: calendar,
            now: now
        )

        assert(decision == .new(expected), "A date without an entry should create a draft at start of day")
    }

    private static var gregorianCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private static func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        calendar: Calendar
    ) -> Date {
        DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date!
    }
}
