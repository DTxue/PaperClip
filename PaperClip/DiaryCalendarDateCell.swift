import SwiftUI

struct DiaryDateCell: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let hasEntry: Bool
    let isFuture: Bool
    let action: () -> Void

    private let cal = Calendar.current

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(cal.component(.day, from: date))")
                    .font(.caption.monospacedDigit())
                    .fontWeight(isToday || isSelected ? .bold : .regular)
                    .foregroundStyle(cellTextColor)
                    .frame(width: 26, height: 26)
                    .background(cellBackground)

                Circle()
                    .fill(isSelected ? Color.white : Color.accentColor)
                    .frame(width: 4, height: 4)
                    .opacity(hasEntry ? 1 : 0)
            }
            .frame(height: 34)
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
    }

    private var cellTextColor: Color {
        if isSelected { return .white }
        if isFuture   { return Color(.tertiaryLabel) }
        if isToday    { return .accentColor }
        return .primary
    }

    @ViewBuilder
    private var cellBackground: some View {
        if isSelected {
            Circle().fill(Color.accentColor)
        } else if isToday {
            Circle().strokeBorder(Color.accentColor, lineWidth: 1.5)
        } else {
            Color.clear
        }
    }
}
