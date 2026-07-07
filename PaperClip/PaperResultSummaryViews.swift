import SwiftUI
import PencilKit

struct PaperResultSnapshot {
    let gotItCount: Int
    let notYetCount: Int
    let unmarkedCount: Int

    init(cardCount: Int, marks: [UUID: String]) {
        var gotIt = 0
        var notYet = 0

        for mark in marks.values {
            switch mark {
            case PracticeMark.gotIt.rawValue:
                gotIt += 1
            case PracticeMark.notYet.rawValue:
                notYet += 1
            default:
                break
            }
        }

        gotItCount = gotIt
        notYetCount = notYet
        unmarkedCount = max(0, cardCount - gotIt - notYet)
    }
}

enum PaperAnswerDrawingPreviewRenderer {
    static func render(_ drawing: PKDrawing) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            guard DrawingDataSupport.hasInk(drawing) else { return nil }
            let spec = HandwritingRenderGeometry.inkCropSpec(
                inkBounds: drawing.bounds,
                padding: 24
            ) ?? HandwritingRenderGeometry.fullCanvasSpec(
                canvasSize: CGSize(width: 320, height: 200)
            )
            guard let spec else { return nil }
            return drawing.image(from: spec.sourceRect, scale: spec.drawingScale)
        }.value
    }
}
