import PDFKit
import PencilKit
import UIKit

enum ReviewSubmissionPageDrawer {
    static func draw(
        document: PDFDocument,
        plan: ReviewSubmissionRenderPlan,
        drawings: [Int: Data],
        context: UIGraphicsImageRendererContext
    ) {
        PDFDrawingRenderSupport.fill(
            .systemGray5,
            in: CGRect(origin: .zero, size: plan.outputLayout.outputSize),
            context: context
        )

        for (offset, pageIndex) in plan.pageIndices.enumerated() {
            guard let page = document.page(at: pageIndex) else { continue }
            let geometry = plan.pageGeometries[offset]
            let destination = plan.outputLayout.pages[offset].destination

            PDFDrawingRenderSupport.fillWhiteBackground(in: destination, context: context)

            PDFDrawingRenderSupport.drawPDFPage(
                page,
                bounds: geometry.displayBounds,
                in: destination,
                context: context.cgContext,
                clip: true
            )

            drawAnswerLayer(
                data: drawings[pageIndex],
                geometry: geometry,
                destination: destination
            )
        }
    }

    private static func drawAnswerLayer(
        data: Data?,
        geometry: ReviewSubmissionPageGeometry,
        destination: CGRect
    ) {
        guard let drawing = PDFDrawingRenderSupport.visibleDrawing(from: data) else { return }
        let drawingImage = drawing.image(
            from: geometry.drawingBounds,
            scale: destination.width / geometry.displayBounds.width
        )
        drawingImage.draw(in: destination)
    }
}
