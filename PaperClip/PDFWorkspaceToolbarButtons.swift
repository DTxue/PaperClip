import SwiftUI

struct PDFWorkspaceToolbarButtons: View {
    let hasActiveAttempt: Bool
    let hasAttempts: Bool
    let canSubmitExam: Bool
    let submitExamTitle: String
    let submitExamSystemImage: String
    let isSubmittingExam: Bool
    let canEditAnswers: Bool
    let isWritingEnabled: Bool
    let isDrawingVisible: Bool
    let onStartExam: () -> Void
    let onShowHistory: () -> Void
    let onSubmit: () -> Void
    let onExport: () -> Void
    let onToggleWriting: () -> Void
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onToggleDrawingVisibility: () -> Void
    let onClearAnswers: () -> Void
    let onShowScratch: () -> Void

    @ViewBuilder
    var body: some View {
        if hasActiveAttempt {
            activeAttemptButtons
        } else {
            Button(action: onStartExam) {
                Label("开始或继续整份 PDF", systemImage: "doc.badge.plus")
            }

            if hasAttempts {
                Button(action: onShowHistory) {
                    Label("考试记录", systemImage: "clock.arrow.circlepath")
                }
            }
        }
    }

    @ViewBuilder
    private var activeAttemptButtons: some View {
        Button(action: onSubmit) {
            Label(submitExamTitle, systemImage: submitExamSystemImage)
        }
        .disabled(isSubmittingExam || !canSubmitExam)

        Button(action: onExport) {
            Image(systemName: "paperplane")
        }
        .accessibilityLabel("导出本次考试页面为长图")

        if canEditAnswers {
            Button(action: onToggleWriting) {
                Image(
                    systemName: isWritingEnabled
                        ? "pencil.tip.crop.circle.badge.minus"
                        : "pencil.tip.crop.circle"
                )
            }
            .tint(isWritingEnabled ? .accentColor : .primary)
            .accessibilityLabel(isWritingEnabled ? "停止书写" : "开始书写")

            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward")
            }

            Button(action: onRedo) {
                Image(systemName: "arrow.uturn.forward")
            }
        }

        Button(action: onToggleDrawingVisibility) {
            Image(systemName: isDrawingVisible ? "eye" : "eye.slash")
        }

        Menu {
            Text("答题内容独立保存，不写入源 PDF")

            if canEditAnswers {
                Button(role: .destructive, action: onClearAnswers) {
                    Label("清除当前页答题", systemImage: "trash")
                }
            }
        } label: {
            Label("答题管理", systemImage: "ellipsis.circle")
        }

        Button(action: onShowScratch) {
            Label("草稿板", systemImage: "scribble.variable")
        }

    }
}
