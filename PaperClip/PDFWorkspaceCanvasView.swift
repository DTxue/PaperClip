import SwiftUI

extension PDFWorkspaceView {
    var canvasSnapshot: PDFWorkspaceCanvasSnapshot {
        session.canvasSnapshot(for: document)
    }

    var workspaceCanvas: some View {
        let snapshot = canvasSnapshot
        return ZStack {
            Color(uiColor: .secondarySystemBackground).ignoresSafeArea()

            PDFKitCanvasView(
                url: snapshot.url,
                drawings: snapshot.drawings,
                gradeStamps: snapshot.gradeStamps,
                isWritingEnabled: snapshot.isWritingEnabled,
                isDrawingVisible: snapshot.isDrawingVisible,
                isSelectionMode: snapshot.isSelectionMode,
                selectionAction: session.pendingSelectionAction,
                selectionActionToken: session.selectionActionToken,
                cancelSelectionToken: session.cancelSelectionToken,
                undoToken: session.undoToken,
                redoToken: session.redoToken,
                clearAnswersToken: session.clearAnswersToken,
                reloadDrawingsToken: session.reloadDrawingsToken,
                onDrawingChanged: saveDrawing,
                onSelectionRectChanged: selectionRectDidChange,
                onCrop: handleSelectionAction,
                onError: { message in
                    session.alert = AppAlert(title: "无法打开 PDF", message: message)
                },
                onCanvasSizesChanged: canvasSizesDidChange
            )

            if snapshot.showsStartOverlay {
                ExamStartOverlay(
                    latestAttempt: snapshot.latestAttempt,
                    attemptCount: snapshot.attemptCount,
                    onStart: { session.isPageSelectionPresented = true },
                    onHistory: openExamHistory,
                    onContinue: { attemptID in activateAttempt(id: attemptID) },
                    onDismiss: { dismiss() }
                )
                .zIndex(3)
            }

            if let rect = session.selectionRect {
                SelectionMenuBar(
                    onSave: { performSelectionAction(.saveMistake) },
                    onShare: { performSelectionAction(.share) },
                    onReselect: resetSelection
                )
                .position(x: rect.midX, y: rect.maxY + 44)
                .transition(.scale(scale: 0.85, anchor: .top).combined(with: .opacity))
                .zIndex(1)
            }

            if session.isSelectionMode {
                SelectionInstructionOverlay(hasSelection: session.selectionRect != nil)
            }

            if session.isScratchPresented {
                FloatingScratchBoard {
                    session.closeScratchBoard()
                }
                .zIndex(2)
            }

            if snapshot.isSubmittingExam {
                ExamSubmittingOverlay()
                    .zIndex(4)
            }
        }
        .safeAreaInset(edge: .top, alignment: .leading, spacing: 0) {
            if snapshot.hasActiveAttempt {
                PDFExamExitButton(
                    isDisabled: snapshot.isSubmittingExam,
                    action: { session.isExitExamConfirmationPresented = true }
                )
                .padding(.top, 8)
                .padding(.leading, 12)
                .padding(.bottom, 6)
            }
        }
    }
}
