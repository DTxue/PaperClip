import SwiftUI

extension PDFPageExportView {
    func startExport(_ destination: PDFPageExportDestination) {
        exportTaskSlot.cancel()
        _ = exportTaskSlot.start { taskID in
            await export(destination, taskID: taskID)
            exportTaskSlot.finish(taskID)
        }
    }

    @MainActor
    func export(_ destination: PDFPageExportDestination, taskID: UUID) async {
        isRendering = true

        do {
            let result = try await PDFPageExportFlow.export(
                destination: destination,
                request: PDFPageExportRequest(
                    documentURL: documentURL,
                    selectedIndices: selectedIndices,
                    drawings: drawings,
                    canvasSizes: canvasSizes,
                    screenScale: displayScale
                )
            )
            guard exportTaskSlot.isCurrent(taskID) else { return }
            var generatedImageData: Data?
            result.apply(to: &generatedImageData, alert: &alert)
            if let generatedImageData {
                generatedImage = ShareImageRequestFactory.request(from: generatedImageData)
            }
        } catch {
            guard exportTaskSlot.isCurrent(taskID) else { return }
            alert = PDFPageExportDestinationFailureAlert.alert(
                destination: destination,
                error: error
            )
        }

        guard exportTaskSlot.isCurrent(taskID) else { return }
        isRendering = false
    }

    func cancelExport() {
        exportTaskSlot.cancel()
        isRendering = false
    }

    @MainActor
    func loadPageCount() async {
        pageCount = nil
        selectedIndices = []
        generatedImage = nil
        cancelExport()

        let documentURL = documentURL
        let loadedPageCount = await PDFPageDocumentReader.pageCount(at: documentURL)
        guard !Task.isCancelled else { return }
        pageCount = loadedPageCount
    }
}
