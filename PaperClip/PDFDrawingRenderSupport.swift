import PencilKit
@preconcurrency import PDFKit
import UIKit

enum PDFDrawingRenderSupport {
    static func visibleDrawing(from data: Data?) -> PKDrawing? {
        DrawingDataSupport.visibleDrawing(from: data)
    }

    static func drawPDFPage(
        _ page: PDFPage,
        box: PDFDisplayBox = .mediaBox,
        bounds: CGRect,
        in destination: CGRect,
        context: CGContext,
        clip: Bool = false
    ) {
        guard let scale = PDFPageRenderGeometry.pageScale(
            bounds: bounds,
            destination: destination
        ) else { return }

        context.saveGState()
        if clip {
            context.clip(to: destination)
        }
        context.translateBy(x: destination.minX, y: destination.maxY)
        context.scaleBy(x: scale.x, y: -scale.y)
        context.translateBy(x: -bounds.minX, y: -bounds.minY)
        page.draw(with: box, to: context)
        context.restoreGState()
    }

    static func fillWhiteBackground(
        in rect: CGRect,
        context: UIGraphicsImageRendererContext
    ) {
        ImageRenderSupport.fillWhiteBackground(in: rect, context: context)
    }

    static func fill(
        _ color: UIColor,
        in rect: CGRect,
        context: UIGraphicsImageRendererContext
    ) {
        ImageRenderSupport.fill(color, in: rect, context: context)
    }
}
