import Foundation

@main
struct DiaryCalendarSupportTests {
    static func main() {
        testCalendarDaysPadMonthToFullWeeksStartingMonday()
        testEntryIDByDateNormalizesDatesAndKeepsLatestDuplicate()
        testMonthLabelUsesChineseYearMonthFormat()
        print("DiaryCalendarSupportTests: 3 passed")
    }

    private static func testCalendarDaysPadMonthToFullWeeksStartingMonday() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let month = date(year: 2026, month: 7, day: 15, calendar: calendar)
        let days = DiaryCalendarSupport.calendarDays(for: month, calendar: calendar)

        expect(days.count == 35, "July 2026 should fit into five Monday-first calendar rows")
        expect(days.prefix(2).allSatisfy { $0 == nil }, "month grid should include leading placeholders before Wednesday")
        expect(calendar.component(.day, from: days[2]!) == 1, "first real cell should be day 1")
        expect(calendar.component(.day, from: days[32]!) == 31, "last real day should be day 31")
        expect(days.suffix(2).allSatisfy { $0 == nil }, "month grid should include trailing placeholders after Friday")
    }

    private static func testEntryIDByDateNormalizesDatesAndKeepsLatestDuplicate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let firstID = UUID()
        let latestID = UUID()
        let entries = [
            DiaryCalendarEntryRowData(
                id: firstID,
                date: date(year: 2026, month: 7, day: 5, hour: 8, calendar: calendar)
            ),
            DiaryCalendarEntryRowData(
                id: latestID,
                date: date(year: 2026, month: 7, day: 5, hour: 21, calendar: calendar)
            )
        ]

        let entryIDByDate = DiaryCalendarSupport.entryIDByDate(from: entries, calendar: calendar)
        let startOfDay = date(year: 2026, month: 7, day: 5, calendar: calendar)

        expect(entryIDByDate.count == 1, "same-day entries should share one calendar key")
        expect(entryIDByDate[startOfDay] == latestID, "later duplicate rows should win like the previous Dictionary merge")
    }

    private static func testMonthLabelUsesChineseYearMonthFormat() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let month = date(year: 2026, month: 7, day: 5, calendar: calendar)

        expect(
            DiaryCalendarSupport.monthLabel(for: month) == "2026年7月",
            "month label should be shared by diary calendar views"
        )
    }

    private static func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        calendar: Calendar
    ) -> Date {
        calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour
        ))!
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
