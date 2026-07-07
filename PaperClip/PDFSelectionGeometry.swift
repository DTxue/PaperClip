import CoreGraphics
import Foundation

enum PDFSelectionGeometry {
    static let minimumSelectionSize = CGSize(width: 32, height: 32)

    static func handle(at point: CGPoint, in rect: CGRect) -> PDFSelectionHandle? {
        PDFSelectionHandleGeometry.handle(at: point, in: rect)
    }

    static func point(for handle: PDFSelectionHandle, in rect: CGRect) -> CGPoint {
        PDFSelectionHandleGeometry.point(for: handle, in: rect)
    }

    static func resizedRect(
        _ rect: CGRect,
        using handle: PDFSelectionHandle,
        translation: CGPoint
    ) -> CGRect {
        var left = rect.minX
        var right = rect.maxX
        var top = rect.minY
        var bottom = rect.maxY

        switch handle {
        case .topLeft:
            left += translation.x
            top += translation.y
        case .top:
            top += translation.y
        case .topRight:
            right += translation.x
            top += translation.y
        case .right:
            right += translation.x
        case .bottomRight:
            right += translation.x
            bottom += translation.y
        case .bottom:
            bottom += translation.y
        case .bottomLeft:
            left += translation.x
            bottom += translation.y
        case .left:
            left += translation.x
        }

        return normalizedRect(
            from: CGPoint(x: left, y: top),
            to: CGPoint(x: right, y: bottom)
        )
    }

    static func proposedRect(
        adjustment: PDFSelectionAdjustment,
        startPoint: CGPoint,
        currentPoint: CGPoint,
        startRect: CGRect
    ) -> CGRect {
        switch adjustment {
        case .creating:
            normalizedRect(from: startPoint, to: currentPoint)
        case .moving:
            startRect.offsetBy(
                dx: currentPoint.x - startPoint.x,
                dy: currentPoint.y - startPoint.y
            )
        case let .resizing(handle):
            resizedRect(
                startRect,
                using: handle,
                translation: CGPoint(
                    x: currentPoint.x - startPoint.x,
                    y: currentPoint.y - startPoint.y
                )
            )
        }
    }

    static func isLargeEnough(_ rect: CGRect?) -> Bool {
        guard let rect else { return false }
        return rect.width >= minimumSelectionSize.width
            && rect.height >= minimumSelectionSize.height
    }

    static func constrained(_ rect: CGRect, to bounds: CGRect) -> CGRect {
        RectGeometry.constrained(rect, to: bounds)
    }

    static func normalizedRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        RectGeometry.normalizedRect(from: start, to: end)
    }
}
