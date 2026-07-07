import SwiftData
import UIKit

enum MistakeSelectionCaptureTransaction {
    @MainActor
    static func saveCapturedSelection(
        image: UIImage,
        originalWidth: Double,
        originalHeight: Double,
        sourceDocumentTitle: String,
        in modelContext: ModelContext,
        isCurrentTask: () -> Bool
    ) async throws -> MistakeCard? {
        guard MistakeSelectionCaptureRequest.isValidOriginalDimension(originalWidth),
              MistakeSelectionCaptureRequest.isValidOriginalDimension(originalHeight)
        else {
            throw CocoaError(.fileWriteUnknown)
        }

        let fileName = try await StorageService.saveCardImage(image)
        guard isCurrentTask(), !Task.isCancelled else {
            StorageService.deleteFileBestEffort(
                .cardImage(fileName: fileName),
                context: "取消保存错题截图后的文件清理失败"
            )
            return nil
        }

        guard let request = MistakeSelectionCaptureSupport.makeRequest(
            imageFileName: fileName,
            originalWidth: originalWidth,
            originalHeight: originalHeight,
            sourceDocumentTitle: sourceDocumentTitle
        ) else {
            StorageService.deleteFileBestEffort(
                .cardImage(fileName: fileName),
                context: "无效错题截图保存请求后的文件清理失败"
            )
            throw CocoaError(.fileWriteUnknown)
        }

        let card = MistakeCard(
            imageFileName: request.imageFileName,
            originalWidth: request.originalWidth,
            originalHeight: request.originalHeight,
            recognitionStatus: RecognitionStatus.completed.rawValue,
            sourceDocumentTitle: request.sourceDocumentTitle
        )
        modelContext.insert(card)

        do {
            // 后台服务会从持久层回查卡片，因此必须先保存再入队。
            try modelContext.saveOrRollbackIfNeeded()
        } catch {
            StorageService.deleteFileBestEffort(
                at: card.imageURL,
                context: "保存错题截图失败后的文件清理失败"
            )
            throw error
        }

        return card
    }
}
