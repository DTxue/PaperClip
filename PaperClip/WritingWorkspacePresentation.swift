import SwiftUI

extension WritingWorkspaceView {
    @ToolbarContentBuilder
    var writingWorkspaceToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(action: showFullscreenWriter) {
                Label("全屏书写", systemImage: "arrow.up.left.and.arrow.down.right")
            }
            .disabled(phase.isWorking)

            Button(action: handleReviewButtonTapped) {
                Label("批阅", systemImage: "checkmark.seal")
            }
            .disabled(phase.isWorking)
        }
    }

    func workspacePresentationModifiers<Content: View>(_ content: Content) -> some View {
        content
            .sheet(isPresented: $isShowingRecognitionSheet) {
                WritingRecognitionReviewSheet(text: recognitionText) { confirmedText in
                    restartReviewTask {
                        await submitForReview(confirmedText: confirmedText)
                    }
                }
            }
            .sheet(isPresented: $isShowingPaperSizing) {
                WritingPaperSizingView(
                    paperStyle: paperStyle,
                    paperWidth: $paperWidth,
                    paperHeight: $paperHeight,
                    rulingSpacing: $rulingSpacing,
                    onReset: resetPaperMetrics
                )
            }
            .sheet(item: $presentedReview, onDismiss: handleReviewSheetDismissed) { review in
                NavigationStack {
                    WritingReviewDetailLoader(reviewID: review.id) {
                        shouldRestartReviewAfterDismiss = true
                    }
                }
            }
            .fullScreenCover(isPresented: $isShowingFullscreenWriter) {
                WritingFullscreenWriterView(
                    prompt: prompt,
                    drawingStore: drawingStore,
                    paperStyle: $paperStyle,
                    blackPaperMode: $blackPaperMode,
                    paperWidth: $paperWidth,
                    paperHeight: $paperHeight,
                    rulingSpacing: $rulingSpacing,
                    availablePaperStyles: availablePaperStyles,
                    reloadToken: drawingRevision,
                    onDrawingChanged: scheduleAutosave,
                    onSave: { _ = saveDraft() }
                )
            }
    }
}
