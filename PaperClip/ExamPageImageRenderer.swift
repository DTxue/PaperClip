import UIKit
import PencilKit
@preconcurrency import PDFKit

enum ExamPageImageRenderer {
    private static let targetPixelWidth: CGFloat = 1_400

    struct PageRenderResult {
        let jpegData: Data
        let pixelSize: CGSize
    }

    static func renderJPEGData(
        pdfURL: URL,
        drawings: [Int: Data],
        canvasSizes: [Int: CGSize]
    ) throws -> [Data] {
        let pdfDocument = try PDFRenderSupport.document(at: pdfURL)

        var pages: [Data] = []
        pages.reserveCapacity(pdfDocument.pageCount)

        for index in 0..<pdfDocument.pageCount {
            pages.append(try renderPage(
                in: pdfDocument,
                pageIndex: index,
                drawingData: drawings[index],
                canvasSize: canvasSizes[index]
            ).jpegData)
        }

        guard !pages.isEmpty else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return pages
    }

    static func renderPageJPEGData(
        pdfURL: URL,
        pageIndex: Int,
        drawingData: Data?,
        canvasSize: CGSize?
    ) throws -> PageRenderResult {
        let pdfDocument = try PDFRenderSupport.document(at: pdfURL)
        return try renderPage(
            in: pdfDocument,
            pageIndex: pageIndex,
            drawingData: drawingData,
            canvasSize: canvasSize
        )
    }

    private static func renderPage(
        in pdfDocument: PDFDocument,
        pageIndex: Int,
        drawingData: Data?,
        canvasSize: CGSize?
    ) throws -> PageRenderResult {
        guard let page = pdfDocument.page(at: pageIndex) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let mediaBox = page.bounds(for: .mediaBox)
        guard let size = PDFLongImageLayoutSupport.outputSize(
            sourceSize: mediaBox.size,
            outputWidth: targetPixelWidth
        ) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let data = try autoreleasepool {
            let image = PDFRenderSupport.opaqueImage(size: size) { context in
                let destination = CGRect(origin: .zero, size: size)
                PDFPageDrawingRenderer.drawPage(
                    page,
                    mediaBox: mediaBox,
                    destination: destination,
                    drawingData: drawingData,
                    canvasSize: canvasSize ?? mediaBox.size,
                    outputPixelWidth: size.width,
                    context: context
                )
            }
            return try PDFRenderSupport.jpegData(from: image, profile: .examPage)
        }
        return PageRenderResult(jpegData: data, pixelSize: size)
    }

}
