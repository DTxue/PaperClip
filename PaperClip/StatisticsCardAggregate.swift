import Foundation
import SwiftData

struct StatisticsCardAggregate {
    let masterySummary: MasteryStatusSummary
    let subjectData: [(subject: String, count: Int)]
    let monthlyData: [StatisticsMonthPoint]
    let topTags: [(tag: String, count: Int)]

    static let empty = StatisticsCardAggregate(
        masterySummary: .empty,
        subjectData: [],
        monthlyData: [],
        topTags: []
    )

    static func make(
        modelContext: ModelContext,
        calendar: Calendar,
        now: Date,
        propertiesToFetch: [PartialKeyPath<MistakeCard>]
    ) throws -> StatisticsCardAggregate {
        let months = StatisticsDateBuckets.recentBuckets(
            endingAt: now,
            component: .month,
            count: 12,
            calendar: calendar
        )
        guard !months.isEmpty else { return .empty }
        let monthSet = Set(months)

        var masteryCounter = MasteryStatusCounter()
        var subjectCounts: [String: Int] = [:]
        var countsByMonth: [Date: Int] = [:]
        var tagCounts: [String: Int] = [:]
        subjectCounts.reserveCapacity(Subject.allCases.count)
        countsByMonth.reserveCapacity(months.count)

        let cards = try modelContext.fetchMistakeCards(
            subject: nil,
            propertiesToFetch: propertiesToFetch
        )
        for card in cards {
            masteryCounter.add(card.status)
            subjectCounts[card.subject, default: 0] += 1
            addMonthCount(
                for: card.createdAt,
                monthSet: monthSet,
                calendar: calendar,
                countsByMonth: &countsByMonth
            )
            MistakeTagSummary.add(card.tags, to: &tagCounts)
        }

        return StatisticsCardAggregate(
            masterySummary: masteryCounter.summary,
            subjectData: sortedKnownSubjectData(subjectCounts),
            monthlyData: months.map { month in
                StatisticsMonthPoint(month: month, count: countsByMonth[month, default: 0])
            },
            topTags: MistakeTagSummary.topTags(from: tagCounts, limit: 10)
        )
    }

    private static let subjectSortOrder: [String: Int] = Dictionary(
        uniqueKeysWithValues: Subject.allCases.enumerated().map { index, subject in
            (subject.rawValue, index)
        }
    )

    private static func addMonthCount(
        for date: Date,
        monthSet: Set<Date>,
        calendar: Calendar,
        countsByMonth: inout [Date: Int]
    ) {
        guard let month = StatisticsDateBuckets.bucketStart(
            for: date,
            component: .month,
            calendar: calendar
        ), monthSet.contains(month) else {
            return
        }
        countsByMonth[month, default: 0] += 1
    }

    private static func sortedKnownSubjectData(
        _ subjectCounts: [String: Int]
    ) -> [(subject: String, count: Int)] {
        subjectCounts
            .filter { subjectSortOrder[$0.key] != nil }
            .map { (subject: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return subjectSortOrder[lhs.subject, default: Int.max]
                    < subjectSortOrder[rhs.subject, default: Int.max]
            }
    }
}
