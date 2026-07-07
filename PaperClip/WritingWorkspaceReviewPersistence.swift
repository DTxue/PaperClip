import SwiftUI

extension WritingWorkspaceView {
    func refreshReviewSummaries() {
        do {
            recentReviews = try modelContext.fetchWritingReviews(
                promptID: prompt.id,
                limit: 3,
                propertiesToFetch: WritingReviewRowData.propertiesToFetch
            ).map(WritingReviewRowData.init)
        } catch {
            alert = AppAlert(title: "无法读取作文批阅记录", error: error)
            recentReviews = []
        }
    }

    @discardableResult
    func updateActiveDraftReviewState(
        status: WritingReviewStatus,
        recognizedText: String? = nil,
        refreshUpdatedAt: Bool = false
    ) -> Bool {
        guard let activeDraft else { return false }
        var hasChanges = false

        if let recognizedText, activeDraft.recognizedText != recognizedText {
            activeDraft.recognizedText = recognizedText
            hasChanges = true
        }
        if activeDraft.reviewStatus != status {
            activeDraft.reviewStatus = status
            hasChanges = true
        }
        if refreshUpdatedAt {
            activeDraft.updatedAt = .now
            hasChanges = true
        }

        return hasChanges
    }

    func saveReviewState(failureTitle: String) -> Bool {
        do {
            try WritingReviewTransaction.saveState(in: modelContext)
            return true
        } catch {
            phase = .idle
            alert = AppAlert(title: failureTitle, error: error)
            return false
        }
    }

    func saveFailureReviewState(
        status: WritingReviewStatus,
        originalError: Error,
        alertTitle: String,
        saveFailureTitle: String
    ) {
        updateActiveDraftReviewState(status: status)
        do {
            try WritingReviewTransaction.saveState(in: modelContext)
            alert = AppAlert(title: alertTitle, error: originalError)
        } catch {
            alert = AppAlert(title: saveFailureTitle, error: error)
        }
    }
}
