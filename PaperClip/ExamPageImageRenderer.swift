import UIKit
import PencilKit
@preconcurrency import PDFKit

enum ExamPageImageRenderer {
    private static let targetPixelWidth: CGFloat = 1_400

    static func renderJPEGData(
        pdfURL: URL,
        drawings: [Int: Data],
        canvasSizes: [Int: CGSize]
    ) throws -> [Data] {
        let pdfDocument = try PDFRenderSupport.document(at: pdfURL)

        var pages: [Data] = []
        pages.reserveCapacity(pdfDocument.pageCount)

        for index in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: index) else { continue }
            let mediaBox = page.bounds(for: .mediaBox)
            guard let size = PDFLongImageLayoutSupport.outputSize(
                sourceSize: mediaBox.size,
                outputWidth: targetPixelWidth
            ) else { continue }

            let data = try autoreleasepool {
                let image = PDFRenderSupport.opaqueImage(size: size) { context in
                    let destination = CGRect(origin: .zero, size: size)
                    PDFPageDrawingRenderer.drawPage(
                        page,
                        mediaBox: mediaBox,
                        destination: destination,
                        drawingData: drawings[index],
                        canvasSize: canvasSizes[index] ?? mediaBox.size,
                        outputPixelWidth: size.width,
                        context: context
                    )
                }

                return try PDFRenderSupport.jpegData(from: image, profile: .examPage)
            }
            pages.append(data)
        }

        guard !pages.isEmpty else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return pages
    }

}
