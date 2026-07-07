import SwiftData
import SwiftUI

private let diaryCalendarColumns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

struct DiaryCalendarWeekdayHeader: View {
    var body: some View {
        LazyVGrid(columns: diaryCalendarColumns, spacing: 0) {
            ForEach(DiaryCalendarSupport.weekdayLabels, id: \.self) { label in
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 2)
            }
        }
    }
}

struct DiaryCalendarMonthGrid: View {
    let displayedMonth: Date
    let selection: DiaryListItem?
    let newEntryDate: Date?
    @Binding var alert: AppAlert?
    let onSelectDate: (Date, UUID?) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var entryIDByDate: [Date: UUID] = [:]

    private let cal = Calendar.current

    init(
        displayedMonth: Date,
        selection: DiaryListItem?,
        newEntryDate: Date?,
        alert: Binding<AppAlert?>,
        onSelectDate: @escaping (Date, UUID?) -> Void
    ) {
        self.displayedMonth = displayedMonth
        self.selection = selection
        self.newEntryDate = newEntryDate
        _alert = alert
        self.onSelectDate = onSelectDate
    }

    private var selectedDate: Date? {
        switch selection {
        case .today:        return cal.startOfDay(for: Date())
        case .entry(let e): return cal.startOfDay(for: e.date)
        case nil:           return newEntryDate
        }
    }

    private var calendarDays: [Date?] {
        DiaryCalendarSupport.calendarDays(for: displayedMonth, calendar: cal)
    }

    var body: some View {
        let days = calendarDays
        let entryIDs = entryIDByDate
        let currentSelectedDate = selectedDate
        let now = Date()

        LazyVGrid(columns: diaryCalendarColumns, spacing: 2) {
            ForEach(days.indices, id: \.self) { index in
                let date = days[index]
                if let date {
                    let start = cal.startOfDay(for: date)
                    DiaryDateCell(
                        date: date,
                        isToday: cal.isDateInToday(date),
                        isSelected: currentSelectedDate.map { cal.isDate($0, inSameDayAs: date) } ?? false,
                        hasEntry: entryIDs[start] != nil,
                        isFuture: date > now
                    ) { onSelectDate(date, entryIDs[start]) }
                } else {
                    Color.clear.frame(height: 34)
                }
            }
        }
        .task(id: displayedMonth) {
            refreshEntries()
        }
    }

    private func refreshEntries() {
        do {
            let entries = try modelContext.fetchDiaryEntries(
                inMonthContaining: displayedMonth,
                calendar: cal,
                propertiesToFetch: DiaryCalendarEntryRowData.propertiesToFetch
            ).map(DiaryCalendarEntryRowData.init)
            entryIDByDate = DiaryCalendarSupport.entryIDByDate(from: entries, calendar: cal)
        } catch {
            entryIDByDate = [:]
            alert = AppAlert(title: "无法读取日历日记", error: error)
        }
    }
}
