import CoreGraphics
import Foundation

struct HandwritingRenderSpec: Equatable {
    let sourceRect: CGRect
    let outputSize: CGSize
    let drawingScale: CGFloat
}

enum HandwritingRenderGeometry {
    static let defaultInkPadding: CGFloat = 20
    static let defaultDrawingScale: CGFloat = 2

    static func inkCropSpec(
        inkBounds: CGRect,
        padding: CGFloat = defaultInkPadding,
        scale: CGFloat = defaultDrawingScale
    ) -> HandwritingRenderSpec? {
        guard inkBounds.width > 0,
              inkBounds.height > 0,
              padding >= 0,
              scale > 0
        else { return nil }

        let sourceRect = inkBounds.standardized.insetBy(dx: -padding, dy: -padding)
        guard sourceRect.width > 0, sourceRect.height > 0 else { return nil }

        return HandwritingRenderSpec(
            sourceRect: sourceRect,
            outputSize: CGSize(
                width: (sourceRect.width * scale).rounded(),
                height: (sourceRect.height * scale).rounded()
            ),
            drawingScale: scale
        )
    }

    static func fullCanvasSpec(
        canvasSize: CGSize,
        scale: CGFloat = defaultDrawingScale
    ) -> HandwritingRenderSpec? {
        guard canvasSize.width > 0,
              canvasSize.height > 0,
              scale > 0
        else { return nil }

        return HandwritingRenderSpec(
            sourceRect: CGRect(origin: .zero, size: canvasSize),
            outputSize: canvasSize,
            drawingScale: scale
        )
    }
}
