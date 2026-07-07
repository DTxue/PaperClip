import SwiftUI

struct DiaryHistoryRow: View {
    let entry: DiaryHistoryRowData

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(entry.date, format: .dateTime.year().month().day())
                .font(.headline)
            HStack(spacing: 8) {
                Text(entry.date, format: Date.FormatStyle().weekday(.wide))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                ForEach(entry.indicators, id: \.kind) { indicator in
                    Image(systemName: indicator.kind.systemImage)
                        .font(.subheadline)
                        .foregroundStyle(indicatorColor(indicator))
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func indicatorColor(_ indicator: DiaryHistoryIndicator) -> Color {
        indicator.isActive ? color(for: indicator.kind) : Color(.systemFill)
    }

    private func color(for kind: DiaryHistoryIndicatorKind) -> Color {
        switch kind {
        case .learned: return .blue
        case .confused: return .orange
        case .noted: return .purple
        case .inspired: return .yellow
        }
    }
}
