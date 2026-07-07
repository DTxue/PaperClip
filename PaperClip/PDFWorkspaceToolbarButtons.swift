import SwiftUI

struct PDFWorkspaceToolbarButtons: View {
    let hasActiveAttempt: Bool
    let hasAttempts: Bool
    let canSubmitExam: Bool
    let isSubmittingExam: Bool
    let isWritingEnabled: Bool
    let isDrawingVisible: Bool
    let isSelectionMode: Bool
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
    let onToggleSelection: () -> Void

    @ViewBuilder
    var body: some View {
        if hasActiveAttempt {
            activeAttemptButtons
        } else {
            Button(action: onStartExam) {
                Label("开始答题", systemImage: "play.circle")
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
            Label("交卷", systemImage: "checkmark.seal")
        }
        .disabled(isSubmittingExam || !canSubmitExam)

        Button(action: onExport) {
            Image(systemName: "paperplane")
        }
        .accessibilityLabel("导出本次考试页面为长图")

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

        Button(action: onToggleDrawingVisibility) {
            Image(systemName: isDrawingVisible ? "eye" : "eye.slash")
        }

        Menu {
            Text("答题内容独立保存，不写入源 PDF")

            Button(role: .destructive, action: onClearAnswers) {
                Label("清除本次答题", systemImage: "trash")
            }
        } label: {
            Label("答题管理", systemImage: "ellipsis.circle")
        }

        Button(action: onShowScratch) {
            Label("草稿板", systemImage: "scribble.variable")
        }

        Button(action: onToggleSelection) {
            Label(
                isSelectionMode ? "退出框选" : "框选",
                systemImage: isSelectionMode ? "xmark" : "viewfinder"
            )
        }
        .tint(isSelectionMode ? .orange : .accentColor)
    }
}
