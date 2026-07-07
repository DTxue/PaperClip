import SwiftUI

// MARK: - 日记日历侧边栏

struct DiaryCalendarView: View {
    let selection: DiaryListItem?
    let newEntryDate: Date?
    @Binding var alert: AppAlert?
    let onSelectDate: (Date, UUID?) -> Void

    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())

    private let cal = Calendar.current

    private var isCurrentMonth: Bool {
        cal.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
    }

    private var monthLabel: String {
        DiaryCalendarSupport.monthLabel(for: displayedMonth)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                Button { shiftMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.semibold))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthLabel)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                if !isCurrentMonth {
                    Button("今天") {
                        displayedMonth = cal.startOfMonth(for: Date())
                    }
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(width: 30, height: 14)
                }

                Button { shiftMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isCurrentMonth)
                .foregroundStyle(isCurrentMonth ? Color(.systemFill) : .primary)
            }

            DiaryCalendarWeekdayHeader()

            DiaryCalendarMonthGrid(
                displayedMonth: displayedMonth,
                selection: selection,
                newEntryDate: newEntryDate,
                alert: $alert,
                onSelectDate: onSelectDate
            )
            .id(displayedMonth)
        }
    }

    private func shiftMonth(by delta: Int) {
        guard let next = cal.date(byAdding: .month, value: delta, to: displayedMonth) else { return }
        if delta > 0, cal.compare(next, to: Date(), toGranularity: .month) == .orderedDescending { return }
        displayedMonth = cal.startOfMonth(for: next)
    }
}
