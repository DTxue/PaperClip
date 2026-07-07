import CoreGraphics

enum RectGeometry {
    static func normalizedRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }

    static func constrained(_ rect: CGRect, to bounds: CGRect) -> CGRect {
        guard !bounds.isEmpty else { return rect }

        var result = rect
        if result.width > bounds.width {
            result.origin.x = bounds.minX
            result.size.width = bounds.width
        } else {
            result.origin.x = min(max(result.minX, bounds.minX), bounds.maxX - result.width)
        }

        if result.height > bounds.height {
            result.origin.y = bounds.minY
            result.size.height = bounds.height
        } else {
            result.origin.y = min(max(result.minY, bounds.minY), bounds.maxY - result.height)
        }
        return result
    }
}
