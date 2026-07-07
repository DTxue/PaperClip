import CoreGraphics
@preconcurrency import PDFKit

struct PDFPageLongImageSource {
    let index: Int
    let page: PDFPage
    let mediaBox: CGRect

    var sourceSize: CGSize {
        mediaBox.size
    }

    static func sources(
        in document: PDFDocument,
        pageIndices: [Int]
    ) -> [PDFPageLongImageSource] {
        var sources: [PDFPageLongImageSource] = []
        sources.reserveCapacity(pageIndices.count)

        for index in pageIndices {
            guard let page = document.page(at: index) else { continue }
            let mediaBox = page.bounds(for: .mediaBox)
            guard mediaBox.width > 0, mediaBox.height > 0 else { continue }
            sources.append(
                PDFPageLongImageSource(
                    index: index,
                    page: page,
                    mediaBox: mediaBox
                )
            )
        }

        return sources
    }

    static func pageInputs(
        from sources: [PDFPageLongImageSource]
    ) -> [(index: Int, sourceSize: CGSize)] {
        sources.map { (index: $0.index, sourceSize: $0.sourceSize) }
    }
}
