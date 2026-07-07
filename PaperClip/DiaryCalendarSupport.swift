import Foundation

struct DiaryCalendarEntryRowData: Identifiable, Equatable {
    let id: UUID
    let date: Date

    init(id: UUID, date: Date) {
        self.id = id
        self.date = date
    }

    init(entry: DiaryEntry) {
        self.id = entry.id
        self.date = entry.date
    }

    static var propertiesToFetch: [PartialKeyPath<DiaryEntry>] {
        [\.id, \.date]
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}

enum DiaryCalendarSupport {
    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    static let weekdayLabels: [String] = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        let symbols = formatter.shortWeekdaySymbols ?? ["日", "一", "二", "三", "四", "五", "六"]
        return Array(symbols.dropFirst()) + symbols.prefix(1)
    }()

    static func calendarDays(
        for displayedMonth: Date,
        calendar: Calendar
    ) -> [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: displayedMonth),
              let dayCount = calendar.range(of: .day, in: .month, for: displayedMonth)?.count
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leadingEmptyDays = (firstWeekday - 2 + 7) % 7
        var days = Array<Date?>(repeating: nil, count: leadingEmptyDays)
        days += (0..<dayCount).map { calendar.date(byAdding: .day, value: $0, to: interval.start) }
        days += Array(repeating: nil, count: (7 - days.count % 7) % 7)
        return days
    }

    static func entryIDByDate(
        from entries: [DiaryCalendarEntryRowData],
        calendar: Calendar
    ) -> [Date: UUID] {
        var entryIDByDate: [Date: UUID] = [:]
        entryIDByDate.reserveCapacity(entries.count)
        for entry in entries {
            entryIDByDate[calendar.startOfDay(for: entry.date)] = entry.id
        }
        return entryIDByDate
    }

    static func monthLabel(for date: Date) -> String {
        monthFormatter.string(from: date)
    }
}
