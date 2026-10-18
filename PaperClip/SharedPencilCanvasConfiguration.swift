import PencilKit
import UIKit

extension PKCanvasView {
    func configureSharedPencilCanvas(
        backgroundColor: UIColor,
        isOpaque: Bool
    ) {
        self.backgroundColor = backgroundColor
        self.isOpaque = isOpaque
        drawingPolicy = .pencilOnly
        isScrollEnabled = false
    }

    func updateSharedPencilCanvas(
        backgroundColor: UIColor,
        isOpaque: Bool
    ) {
        if self.backgroundColor != backgroundColor {
            self.backgroundColor = backgroundColor
        }
        if self.isOpaque != isOpaque {
            self.isOpaque = isOpaque
        }
    }
}
