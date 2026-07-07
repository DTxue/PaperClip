import SwiftUI

extension WritingWorkspaceView {
    func handlePaperSettingsChange(_ snapshot: WritingPaperSettingsSnapshot) {
        if !availablePaperStyles.contains(snapshot.style) {
            paperStyle = .lined
            return
        }

        let clampedSize = WritingPaperMetrics.clampedSize(
            width: snapshot.width,
            height: snapshot.height
        )
        if Double(clampedSize.width) != snapshot.width {
            paperWidth = Double(clampedSize.width)
            return
        }
        if Double(clampedSize.height) != snapshot.height {
            paperHeight = Double(clampedSize.height)
            return
        }

        let clampedSpacing = WritingPaperMetrics.clampedRulingSpacing(snapshot.rulingSpacing)
        if clampedSpacing != snapshot.rulingSpacing {
            rulingSpacing = clampedSpacing
            return
        }

        scheduleAutosave()
    }

    func handleScenePhaseChange(_ newValue: ScenePhase) {
        if newValue != .active {
            saveDraft()
        }
    }

    func showFullscreenWriter() {
        isShowingFullscreenWriter = true
    }

    func handleReviewButtonTapped() {
        if let latestReview = recentReviews.first {
            presentedReview = latestReview
        } else {
            restartReviewTask { await startReview() }
        }
    }

    func handleReviewSheetDismissed() {
        guard shouldRestartReviewAfterDismiss else { return }
        shouldRestartReviewAfterDismiss = false
        restartReviewTask { await startReview() }
    }

    func restartReviewTask(_ operation: @escaping @MainActor () async -> Void) {
        _ = reviewTaskSlot.start { taskID in
            await operation()
            reviewTaskSlot.finish(taskID)
        }
    }
}
