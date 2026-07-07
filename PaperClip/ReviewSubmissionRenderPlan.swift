import PDFKit

struct ReviewSubmissionRenderPlan {
    let pageIndices: [Int]
    let pageGeometries: [ReviewSubmissionPageGeometry]
    let outputLayout: PDFLongImageStackLayout

    static func make(
        document: PDFDocument,
        pageIndices: [Int],
        maximumPageCount: Int
    ) throws -> ReviewSubmissionRenderPlan {
        guard !pageIndices.isEmpty, pageIndices.count <= maximumPageCount else {
            throw ReviewSubmissionRenderError.invalidSelection
        }
        guard let uniqueIndices = PDFPageExportSelectionSupport.sortedUniqueIndices(
            pageIndices,
            maximumCount: maximumPageCount,
            pageCount: document.pageCount
        ) else {
            throw ReviewSubmissionRenderError.invalidSelection
        }

        let pageGeometries = try uniqueIndices.map { index in
            try pageGeometry(in: document, at: index)
        }
        guard let outputLayout = ReviewSubmissionRenderLayout.outputLayout(for: pageGeometries) else {
            throw ReviewSubmissionRenderError.imageTooLarge
        }

        return ReviewSubmissionRenderPlan(
            pageIndices: uniqueIndices,
            pageGeometries: pageGeometries,
            outputLayout: outputLayout
        )
    }

    private static func pageGeometry(
        in document: PDFDocument,
        at index: Int
    ) throws -> ReviewSubmissionPageGeometry {
        guard let page = document.page(at: index) else {
            throw ReviewSubmissionRenderError.unsupportedPage
        }
        let mediaBounds = page.bounds(for: .mediaBox)
        let cropBounds = page.bounds(for: .cropBox)
        guard let geometry = ReviewSubmissionGeometry.pageGeometry(
            mediaBounds: mediaBounds,
            cropBounds: cropBounds
        ) else {
            throw ReviewSubmissionRenderError.unsupportedPage
        }
        return geometry
    }
}
