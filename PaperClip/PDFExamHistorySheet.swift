import SwiftUI

struct ExamAttemptHistoryView: View {
    let attempts: [ExamAttemptHistoryRowData]
    let onOpen: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let snapshot = ExamAttemptHistorySnapshot(attempts: attempts)

        NavigationStack {
            Group {
                if snapshot.rows.isEmpty {
                    ContentUnavailableView("暂无考试记录", systemImage: "doc.text")
                } else {
                    List {
                        ForEach(snapshot.rows) { row in
                            Button {
                                onOpen(row.id)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: row.iconName)
                                        .foregroundStyle(color(for: row))
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(row.createdAt, format: .dateTime.year().month().day().hour().minute())
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Text("\(row.pageCount) 页：\(row.pageSummary)")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Text(row.statusTitle)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(color(for: row))
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("考试记录，\(row.pageCount)页，\(row.statusTitle)")
                        }
                    }
                }
            }
            .navigationTitle("考试记录")
            .navigationBarTitleDisplayMode(.inline)
            .closeToolbar { dismiss() }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func color(for row: ExamAttemptHistoryDisplayRow) -> Color {
        row.statusStyle.color
    }
}
