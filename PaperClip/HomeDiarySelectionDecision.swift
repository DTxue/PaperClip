import Foundation

enum HomeDiarySelectionDecision: Equatable {
    case today
    case existing(UUID)
    case new(Date)

    static func decision(
        for date: Date,
        entryID: UUID?,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> HomeDiarySelectionDecision {
        let start = calendar.startOfDay(for: date)
        if calendar.isDate(start, inSameDayAs: now) {
            return .today
        }
        if let entryID {
            return .existing(entryID)
        }
        return .new(start)
    }
}
