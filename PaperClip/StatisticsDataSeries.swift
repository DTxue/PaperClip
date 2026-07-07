import Foundation

struct StatisticsMonthPoint: Identifiable {
    let month: Date
    let count: Int
    var id: Date { month }
    var hasEntries: Bool { count > 0 }
}

struct StatisticsWeekPoint: Identifiable {
    let week: Date
    let gotIt: Int
    let notYet: Int
    var id: Date { week }
    var total: Int { gotIt + notYet }
    var hasEntries: Bool { total > 0 }
}

enum StatisticsDateBuckets {
    static func bucketStart(
        for date: Date,
        component: Calendar.Component,
        calendar: Calendar
    ) -> Date? {
        calendar.dateInterval(of: component, for: date)?.start
    }

    static func recentBuckets(
        endingAt date: Date,
        component: Calendar.Component,
        count: Int,
        calendar: Calendar
    ) -> [Date] {
        guard count > 0,
              let currentBucket = bucketStart(
                for: date,
                component: component,
                calendar: calendar
              )
        else { return [] }

        return (0..<count).reversed().compactMap {
            calendar.date(byAdding: component, value: -$0, to: currentBucket)
        }
    }
}
