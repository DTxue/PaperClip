import Foundation
import SwiftData

struct StatisticsPracticeWeekData {
    static func make(
        modelContext: ModelContext,
        calendar: Calendar,
        now: Date,
        propertiesToFetch: [PartialKeyPath<MistakePracticeLayer>]
    ) throws -> [StatisticsWeekPoint] {
        let weeks = StatisticsDateBuckets.recentBuckets(
            endingAt: now,
            component: .weekOfYear,
            count: 8,
            calendar: calendar
        )
        guard let firstWeek = weeks.first else { return [] }

        var counter = StatisticsPracticeWeekCounter()
        counter.reserveCapacity(weeks.count)
        let layers = try modelContext.fetchMarkedMistakePracticeLayers(
            since: firstWeek,
            propertiesToFetch: propertiesToFetch
        )
        for layer in layers {
            guard let week = StatisticsDateBuckets.bucketStart(
                for: layer.createdAt,
                component: .weekOfYear,
                calendar: calendar
            ) else {
                continue
            }
            counter.add(mark: layer.mark, week: week)
        }

        var points: [StatisticsWeekPoint] = []
        points.reserveCapacity(weeks.count)
        for week in weeks {
            if let point = counter.point(for: week) {
                points.append(point)
            }
        }
        return points
    }
}

private struct StatisticsPracticeWeekCounts {
    var gotIt = 0
    var notYet = 0

    var pointTotal: Int {
        gotIt + notYet
    }

    mutating func add(mark: String) {
        if mark == PracticeMark.gotIt.rawValue {
            gotIt += 1
        } else if mark == PracticeMark.notYet.rawValue {
            notYet += 1
        }
    }
}

private struct StatisticsPracticeWeekCounter {
    private var countsByWeek: [Date: StatisticsPracticeWeekCounts] = [:]

    mutating func reserveCapacity(_ capacity: Int) {
        countsByWeek.reserveCapacity(capacity)
    }

    mutating func add(mark: String, week: Date) {
        countsByWeek[week, default: StatisticsPracticeWeekCounts()].add(mark: mark)
    }

    func point(for week: Date) -> StatisticsWeekPoint? {
        guard let counts = countsByWeek[week],
              counts.pointTotal > 0
        else { return nil }
        return StatisticsWeekPoint(week: week, gotIt: counts.gotIt, notYet: counts.notYet)
    }
}
