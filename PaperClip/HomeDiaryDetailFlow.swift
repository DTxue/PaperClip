import SwiftData
import SwiftUI

extension HomeDiaryDetailView {
    func refreshTodayEntry(calendar: Calendar = .current, now: Date = .now) {
        do {
            todayEntry = try modelContext.fetchDiaryEntry(containing: now, calendar: calendar)
        } catch {
            todayEntry = nil
            alert = AppAlert(title: "无法读取今日日记", error: error)
        }
    }

    func loadTodayDraftIfNeeded(calendar: Calendar = .current, now: Date = .now) {
        let today = calendar.startOfDay(for: now)
        guard loadedDate != today else { return }

        diaryDraft.replace(with: todayEntry)
        loadedDate = today
    }

    func saveToday() {
        guard diaryDraft.hasInput else { return }

        if let entry = todayEntry {
            guard diaryDraft.differs(from: entry) else { return }

            diaryDraft.apply(to: entry)
            entry.updatedAt = .now
            saveTodayEntry(entry)
            return
        }

        let entry = DiaryEntry(date: .now)
        diaryDraft.apply(to: entry)
        entry.updatedAt = .now
        modelContext.insert(entry)
        saveTodayEntry(entry)
    }

    func saveTodayEntry(_ entry: DiaryEntry) {
        do {
            try modelContext.saveOrRollbackIfNeeded()
            todayEntry = entry
        } catch {
            alert = AppAlert(title: "无法保存今日日记", error: error)
        }
    }

    func saveNewEntry(for date: Date) {
        guard diaryDraft.hasInput else { return }

        let entry = DiaryEntry(date: date)
        diaryDraft.apply(to: entry)
        modelContext.insert(entry)
        do {
            try modelContext.saveOrRollbackIfNeeded()
            newEntryDate = nil
            selection = .entry(entry)
        } catch {
            alert = AppAlert(title: "无法保存日记", error: error)
        }
    }
}
