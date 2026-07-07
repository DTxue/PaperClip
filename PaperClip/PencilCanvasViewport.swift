import PencilKit
import UIKit

@MainActor
struct PencilCanvasViewport: Equatable {
    var contentSize: CGSize
    var contentOffset: CGPoint

    func apply(to canvas: PKCanvasView) {
        if canvas.bounces {
            canvas.bounces = false
        }
        if canvas.contentInsetAdjustmentBehavior != .never {
            canvas.contentInsetAdjustmentBehavior = .never
        }
        if canvas.contentSize != contentSize {
            canvas.contentSize = contentSize
        }
        if hypot(
            canvas.contentOffset.x - contentOffset.x,
            canvas.contentOffset.y - contentOffset.y
        ) > 0.5 {
            canvas.setContentOffset(contentOffset, animated: false)
        }
    }
}

extension PKCanvasView {
    func configureSharedPencilCanvas(
        backgroundColor: UIColor,
        isOpaque: Bool,
        viewport: PencilCanvasViewport?
    ) {
        self.backgroundColor = backgroundColor
        self.isOpaque = isOpaque
        drawingPolicy = .pencilOnly
        isScrollEnabled = false
        viewport?.apply(to: self)
    }

    func updateSharedPencilCanvas(
        backgroundColor: UIColor,
        isOpaque: Bool,
        viewport: PencilCanvasViewport?,
        lastViewport: inout PencilCanvasViewport?
    ) {
        if self.backgroundColor != backgroundColor {
            self.backgroundColor = backgroundColor
        }
        if self.isOpaque != isOpaque {
            self.isOpaque = isOpaque
        }
        if lastViewport != viewport {
            viewport?.apply(to: self)
            lastViewport = viewport
        }
    }
}
