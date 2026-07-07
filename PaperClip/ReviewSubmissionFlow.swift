import Foundation
import PDFKit

extension ReviewSubmissionView {
    func generateLongImage() {
        let request = ReviewSubmissionGenerationRequest(
            pdfURL: pdfURL,
            selectedPages: selectedPages,
            drawings: drawings
        )
        guard !request.isEmpty else { return }

        generationTaskSlot.cancel()
        isGenerating = true
        _ = generationTaskSlot.start { taskID in
            do {
                let data = try await ReviewSubmissionGenerationFlow.generateImageData(for: request)
                guard generationTaskSlot.isCurrent(taskID) else { return }
                generatedImage = ShareImageRequestFactory.request(from: data)
            } catch {
                guard generationTaskSlot.isCurrent(taskID) else { return }
                alert = AppAlert(title: "无法生成批阅图片", error: error)
            }
            guard generationTaskSlot.isCurrent(taskID) else { return }
            isGenerating = false
            generationTaskSlot.finish(taskID)
        }
    }

    func cancelGeneration() {
        generationTaskSlot.cancel()
        isGenerating = false
    }

    nonisolated static func hasVisibleDrawing(_ data: Data?) -> Bool {
        ReviewSubmissionRenderer.hasVisibleDrawing(data)
    }

    @MainActor
    func loadPageSelection() async {
        pageCount = nil
        selectedPages = []
        answeredPageSet = []
        generatedImage = nil
        cancelGeneration()

        let pdfURL = pdfURL
        let drawings = drawings
        let selection = await ReviewSubmissionSelectionLoader.load(
            pdfURL: pdfURL,
            drawings: drawings
        )
        guard !Task.isCancelled else { return }
        pageCount = selection.pageCount
        answeredPageSet = selection.answeredPageSet
        selectedPages = selection.selectedPages
    }
}
