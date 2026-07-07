import Foundation

enum ReviewSubmissionSelectionLoader {
    static func load(
        pdfURL: URL,
        drawings: [Int: Data]
    ) async -> ReviewSubmissionPageSelection {
        let pageCount = await PDFPageDocumentReader.pageCount(at: pdfURL)
        return ReviewSubmissionSelectionSupport.makeSelection(
            pageCount: pageCount,
            drawingPageIndices: drawings.keys,
            hasVisibleDrawing: { ReviewSubmissionRenderer.hasVisibleDrawing(drawings[$0]) }
        )
    }
}
