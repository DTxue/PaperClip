import UIKit
import PencilKit
@preconcurrency import PDFKit

enum PDFPageDrawingRenderer {
    static func drawPage(
        _ page: PDFPage,
        mediaBox: CGRect,
        destination: CGRect,
        drawingData: Data?,
        canvasSize: CGSize,
        outputPixelWidth: CGFloat,
        context: UIGraphicsImageRendererContext
    ) {
        PDFDrawingRenderSupport.fillWhiteBackground(in: destination, context: context)
        PDFDrawingRenderSupport.drawPDFPage(
            page,
            bounds: mediaBox,
            in: destination,
            context: context.cgContext
        )

        guard let drawing = PDFDrawingRenderSupport.visibleDrawing(from: drawingData) else {
            return
        }

        let drawingImage = drawing.image(
            from: CGRect(origin: .zero, size: canvasSize),
            scale: PDFLongImageLayoutSupport.drawingImageScale(
                outputPixelWidth: outputPixelWidth,
                canvasWidth: canvasSize.width
            )
        )
        drawingImage.draw(in: destination)
    }
}
