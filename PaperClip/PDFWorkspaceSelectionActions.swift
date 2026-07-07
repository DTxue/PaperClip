import UIKit

extension PDFWorkspaceView {
    func shareSelectionImage(_ image: UIImage, taskID: UUID) async {
        session.isSelectionMode = false
        do {
            let request = try await ShareImageRequestFactory.request(from: image)
            guard isCurrentSelectionActionTask(taskID),
                  !Task.isCancelled else { return }
            session.shareImageRequest = request
        } catch {
            guard isCurrentSelectionActionTask(taskID),
                  !Task.isCancelled else { return }
            session.alert = AppAlert(title: "无法分享截图", error: error)
        }
    }

    func saveSelectionAsMistake(
        image: UIImage,
        width: Double,
        height: Double,
        taskID: UUID
    ) async {
        do {
            guard let card = try await MistakeSelectionCaptureTransaction.saveCapturedSelection(
                image: image,
                originalWidth: width,
                originalHeight: height,
                sourceDocumentTitle: document.title,
                in: modelContext,
                isCurrentTask: { isCurrentSelectionActionTask(taskID) }
            )
            else { return }

            session.currentCard = card
            session.isSelectionMode = false
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            guard isCurrentSelectionActionTask(taskID) else { return }
            session.alert = AppAlert(title: "保存错题截图失败", error: error)
        }
    }
}
