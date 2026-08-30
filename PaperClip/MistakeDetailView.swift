import SwiftUI
import SwiftData
import PencilKit

struct MistakeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let item: MistakeLibraryItem
    let attachments: [MistakeAttachment]
    let attempts: [MistakeReviewAttempt]
    let onRemoved: () -> Void

    @State private var isEditing = false
    @State private var isReviewing = false
    @State private var isConfirmingTrash = false
    @State private var isConfirmingPermanentDelete = false
    @State private var selectedAttempt: MistakeReviewAttempt?
    @State private var alert: AppAlert?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if !attachments.isEmpty {
                        VStack(spacing: 14) {
                            ForEach(attachments) { attachment in
                                MistakeAttachmentThumbnail(fileName: attachment.fileName)
                                    .frame(maxWidth: .infinity, maxHeight: 520)
                                    .background(Color.secondary.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }

                    detailSection("题目") {
                        if item.questionText.isEmpty {
                            Text("这是一道图片错题。")
                        } else {
                            MistakeQuestionTextView(text: item.questionText)
                        }
                    }

                    detailSection("整理信息") {
                        LabeledContent("学科", value: item.subject)
                        LabeledContent("年级", value: item.grade)
                        LabeledContent("学期", value: item.semester)
                        LabeledContent("状态", value: item.status.title)
                        if !item.source.isEmpty { LabeledContent("来源", value: item.source) }
                        if !item.errorReason.isEmpty {
                            LabeledContent(
                                "错误原因",
                                value: item.errorReason.replacingOccurrences(of: ",", with: " · ")
                            )
                        }
                        if !item.tags.isEmpty { LabeledContent("标签", value: item.tags.joined(separator: " · ")) }
                        if let nextReviewAt = item.nextReviewAt {
                            LabeledContent("下次重做") { Text(nextReviewAt, style: .date) }
                        }
                    }

                    detailSection("重做记录") {
                        if attempts.isEmpty {
                            Text("还没有重做记录")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(attempts) { attempt in
                                Button {
                                    selectedAttempt = attempt
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Label(
                                                attempt.outcome.title,
                                                systemImage: attempt.outcome == .correct
                                                    ? "checkmark.circle.fill"
                                                    : "xmark.circle.fill"
                                            )
                                            .foregroundStyle(attempt.outcome == .correct ? .green : .orange)
                                            if !attempt.note.isEmpty {
                                                Text(attempt.note)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        Spacer()
                                        Text(attempt.createdAt, style: .date)
                                            .foregroundStyle(.secondary)
                                        Image(systemName: "chevron.right")
                                            .font(.caption.bold())
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    actionButtons
                }
                .padding(24)
            }
            .navigationTitle("错题详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        do {
                            try MistakeLibraryPersistence.setFavorite(
                                !item.isFavorite,
                                for: item,
                                in: modelContext
                            )
                        } catch {
                            modelContext.rollback()
                            alert = AppAlert(title: "更新收藏失败", error: error)
                        }
                    } label: {
                        Image(systemName: item.isFavorite ? "star.fill" : "star")
                    }
                    Button("编辑") { isEditing = true }
                        .disabled(item.deletedAt != nil)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            MistakeEditorView(item: item)
        }
        .fullScreenCover(isPresented: $isReviewing) {
            MistakeReviewView(item: item, attachments: attachments)
        }
        .sheet(item: $selectedAttempt) { attempt in
            MistakeReviewAttemptDetailView(attempt: attempt)
        }
        .confirmationDialog("移入最近删除？", isPresented: $isConfirmingTrash, titleVisibility: .visible) {
            Button("移入最近删除", role: .destructive) { moveToTrash() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("可在“最近删除”中恢复或永久删除。")
        }
        .confirmationDialog("永久删除这道错题？", isPresented: $isConfirmingPermanentDelete, titleVisibility: .visible) {
            Button("永久删除", role: .destructive) { permanentlyDelete() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("题目图片、重做笔迹和记录将无法恢复。")
        }
        .appAlert($alert)
    }

    @ViewBuilder
    private var actionButtons: some View {
        if item.deletedAt != nil {
            HStack {
                Button("恢复") { restore() }
                    .buttonStyle(.borderedProminent)
                Button("永久删除", role: .destructive) { isConfirmingPermanentDelete = true }
                    .buttonStyle(.bordered)
            }
        } else {
            HStack {
                Button {
                    isReviewing = true
                } label: {
                    Label("开始重做", systemImage: "pencil.and.scribble")
                }
                .buttonStyle(.borderedProminent)
                .disabled(item.status == .archived)

                Button(item.status == .archived ? "取消归档" : "归档") {
                    do {
                        try MistakeLibraryPersistence.toggleArchive(item, in: modelContext)
                    } catch {
                        modelContext.rollback()
                        alert = AppAlert(title: "更新归档状态失败", error: error)
                    }
                }
                .buttonStyle(.bordered)

                Button("删除", role: .destructive) { isConfirmingTrash = true }
                    .buttonStyle(.bordered)
            }
        }
    }

    private func detailSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func moveToTrash() {
        do {
            try MistakeLibraryPersistence.moveToTrash(item, in: modelContext)
            dismissAndClearSelection()
        } catch {
            modelContext.rollback()
            alert = AppAlert(title: "删除错题失败", error: error)
        }
    }

    private func restore() {
        do {
            try MistakeLibraryPersistence.restore(item, in: modelContext)
            dismissAndClearSelection()
        } catch {
            modelContext.rollback()
            alert = AppAlert(title: "恢复错题失败", error: error)
        }
    }

    private func permanentlyDelete() {
        do {
            try MistakeLibraryPersistence.permanentlyDelete(
                item,
                attachments: attachments,
                attempts: attempts,
                in: modelContext
            )
            dismissAndClearSelection()
        } catch {
            alert = AppAlert(title: "永久删除失败", error: error)
        }
    }

    private func dismissAndClearSelection() {
        dismiss()
        onRemoved()
    }
}

private struct MistakeReviewAttemptDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let attempt: MistakeReviewAttempt
    @State private var drawing: PKDrawing

    init(attempt: MistakeReviewAttempt) {
        self.attempt = attempt
        _drawing = State(initialValue: DrawingDataSupport.drawingOrEmpty(from: attempt.drawingData))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    LabeledContent("结果", value: attempt.outcome.title)
                    LabeledContent("时间") {
                        Text(attempt.createdAt, format: .dateTime.year().month().day().hour().minute())
                    }
                    if !attempt.note.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("备注").font(.headline)
                            Text(attempt.note)
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("本次笔迹").font(.headline)
                        PencilDrawingCanvas(
                            drawing: $drawing,
                            isEnabled: false,
                            backgroundColor: .secondarySystemBackground,
                            isOpaque: true,
                            accessibilityLabel: "历史重做笔迹",
                            toolAutosaveName: "MistakeReviewHistory"
                        )
                        .frame(minHeight: 420)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(24)
            }
            .navigationTitle("重做记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
