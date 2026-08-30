import PencilKit
import UIKit

struct PDFCanvasConfiguration: Equatable {
    let isWritingEnabled: Bool
    let isDrawingVisible: Bool
}

@MainActor
enum PDFCanvasFactory {
    static let pencilTouchTypes = [
        NSNumber(value: UITouch.TouchType.pencil.rawValue)
    ]

    static func make(delegate: PKCanvasViewDelegate) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .pencilOnly
        canvas.delegate = delegate
        canvas.isScrollEnabled = false
        canvas.bounces = false
        canvas.alwaysBounceHorizontal = false
        canvas.alwaysBounceVertical = false
        canvas.minimumZoomScale = 1
        canvas.maximumZoomScale = 1
        canvas.drawingGestureRecognizer.allowedTouchTypes = pencilTouchTypes
        canvas.drawingGestureRecognizer.cancelsTouchesInView = true
        canvas.tool = PKInkingTool(.pen, color: .systemBlue, width: 3)
        return canvas
    }

    static func setDrawingSilently(
        _ drawing: PKDrawing,
        in canvas: PKCanvasView,
        delegate: PKCanvasViewDelegate
    ) {
        canvas.delegate = nil
        canvas.drawing = drawing
        canvas.undoManager?.removeAllActions()
        canvas.delegate = delegate
    }

    static func configure(
        _ canvas: PKCanvasView,
        configuration: PDFCanvasConfiguration
    ) {
        let alpha: CGFloat = configuration.isDrawingVisible ? 1 : 0
        if canvas.alpha != alpha {
            canvas.alpha = alpha
        }
        let canDraw = configuration.isWritingEnabled && configuration.isDrawingVisible
        if canvas.isUserInteractionEnabled != canDraw {
            canvas.isUserInteractionEnabled = canDraw
        }
        if canvas.drawingGestureRecognizer.isEnabled != canDraw {
            canvas.drawingGestureRecognizer.isEnabled = canDraw
        }
        if canvas.drawingGestureRecognizer.allowedTouchTypes != pencilTouchTypes {
            canvas.drawingGestureRecognizer.allowedTouchTypes = pencilTouchTypes
        }
    }
}
