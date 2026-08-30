import SwiftUI

struct ExamAttemptHistoryView: View {
    let attempts: [ExamAttemptHistoryRowData]
    let onOpen: (UUID) -> Void
    let onDelete: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pendingDeletion: ExamAttemptHistoryDisplayRow?

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

                                        if let progress = row.attempt.pageProgress {
                                            Label(
                                                "已提交 \(progress.submittedPageIndices.count)/\(progress.pageIndices.count) · 已批阅 \(progress.gradedPageIndices.count)",
                                                systemImage: "doc.text.magnifyingglass"
                                            )
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        }

                                        if let durationText = row.durationText {
                                            HStack(spacing: 10) {
                                                Label(durationText, systemImage: "timer")

                                                if let averageQuestionDurationText = row.averageQuestionDurationText {
                                                    Text("平均 \(averageQuestionDurationText)/题")
                                                }
                                            }
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Text(row.statusTitle)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(color(for: row))
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if row.allowsManualDeletion {
                                    Button(role: .destructive) {
                                        pendingDeletion = row
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                            }
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
        .confirmationDialog(
            "删除考试记录？",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingDeletion = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("删除进行中的记录", role: .destructive) {
                if let id = pendingDeletion?.id {
                    onDelete(id)
                }
                pendingDeletion = nil
            }
            Button("取消", role: .cancel) {
                pendingDeletion = nil
            }
        } message: {
            Text("将删除这条进行中的考试记录及其答题内容，源 PDF 和其他考试记录不受影响。此操作不可撤销。")
        }
    }

    private func color(for row: ExamAttemptHistoryDisplayRow) -> Color {
        row.statusStyle.color
    }
}
