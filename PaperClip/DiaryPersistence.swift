import Foundation
import SwiftData

extension ModelContext {
    func fetchDiaryEntry(id: UUID) throws -> DiaryEntry? {
        let descriptor = FetchDescriptor<DiaryEntry>(
            predicate: #Predicate<DiaryEntry> { entry in
                entry.id == id
            }
        )
        return try fetchFirst(descriptor)
    }

    func fetchDiaryEntry(containing date: Date, calendar: Calendar = .current) throws -> DiaryEntry? {
        let startOfDay = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        let descriptor = FetchDescriptor<DiaryEntry>(
            predicate: #Predicate<DiaryEntry> { entry in
                entry.date >= startOfDay && entry.date < nextDay
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try fetchFirst(descriptor)
    }

    func fetchDiaryEntries(
        inMonthContaining date: Date,
        calendar: Calendar = .current,
        propertiesToFetch: [PartialKeyPath<DiaryEntry>] = []
    ) throws -> [DiaryEntry] {
        let monthInterval = calendar.dateInterval(of: .month, for: date)
        let monthStart = monthInterval?.start ?? calendar.startOfDay(for: date)
        let nextMonthStart = monthInterval?.end
            ?? calendar.date(byAdding: .month, value: 1, to: monthStart)
            ?? date
        var descriptor = FetchDescriptor<DiaryEntry>(
            predicate: #Predicate<DiaryEntry> { entry in
                entry.date >= monthStart && entry.date < nextMonthStart
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetch(descriptor)
    }

    func fetchRecentDiaryEntries(
        limit: Int,
        propertiesToFetch: [PartialKeyPath<DiaryEntry>] = []
    ) throws -> [DiaryEntry] {
        var descriptor = FetchDescriptor<DiaryEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetch(descriptor)
    }

    func fetchKnowledgeItem(id: UUID) throws -> KnowledgeItem? {
        let descriptor = FetchDescriptor<KnowledgeItem>(
            predicate: #Predicate<KnowledgeItem> { item in
                item.id == id
            }
        )
        return try fetchFirst(descriptor)
    }

    func fetchConfirmedKnowledgeItems(
        propertiesToFetch: [PartialKeyPath<KnowledgeItem>] = []
    ) throws -> [KnowledgeItem] {
        var descriptor = FetchDescriptor<KnowledgeItem>(
            predicate: #Predicate<KnowledgeItem> { item in
                item.status == "confirmed"
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetch(descriptor)
    }
}
