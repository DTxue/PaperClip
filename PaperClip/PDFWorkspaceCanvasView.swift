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
                writablePageIndices: session.writablePageIndices(),
                isDrawingVisible: snapshot.isDrawingVisible,
                undoToken: session.undoToken,
                redoToken: session.redoToken,
                clearAnswersToken: session.clearAnswersToken,
                reloadDrawingsToken: session.reloadDrawingsToken,
                requestedPageIndex: session.requestedPDFPageIndex,
                pageNavigationToken: session.pageNavigationToken,
                onDrawingChanged: saveDrawing,
                onError: { message in
                    session.alert = AppAlert(title: "无法打开 PDF", message: message)
                },
                onCurrentPageIndexChanged: { session.currentPDFPageIndex = $0 },
                onCanvasSizesChanged: canvasSizesDidChange
            )

            if snapshot.showsStartOverlay {
                ExamStartOverlay(
                    latestAttempt: snapshot.latestAttempt,
                    currentAttempt: snapshot.currentAttempt,
                    attemptCount: snapshot.attemptCount,
                    onStart: startOrResumeFullExam,
                    onHistory: openExamHistory,
                    onContinue: continueExam(id:),
                    onDismiss: { dismiss() }
                )
                .zIndex(3)
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

            if snapshot.hasActiveAttempt {
                PDFExamExitButton(
                    isDisabled: snapshot.isSubmittingExam,
                    action: { session.isExitExamConfirmationPresented = true }
                )
                .padding(.leading, 12)
                .safeAreaPadding(.top, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .zIndex(5)

                HStack(spacing: 10) {
                    if let progress = snapshot.pageProgress {
                        PDFExamPageProgressBadge(progress: progress)
                    }
                    if let startedAt = snapshot.activeAttemptStartedAt {
                        PDFExamTimerBadge(startedAt: startedAt)
                    }

                    PDFExamSubmitButton(
                        actionState: snapshot.gradingActionState,
                        action: { session.isSubmitConfirmationPresented = true }
                    )
                }
                .padding(.trailing, 12)
                .safeAreaPadding(.top, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .zIndex(5)
            }
        }
    }
}
