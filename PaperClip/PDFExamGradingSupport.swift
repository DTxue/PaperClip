import CoreGraphics

enum PDFExamGradingSupport {
    static func clampedStampAnchor(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0.04), 0.96),
            y: min(max(point.y, 0.04), 0.96)
        )
    }

    static func normalizedPointString(_ point: CGPoint) -> String {
        "\(Double(point.x)),\(Double(point.y))"
    }

    static func normalizedStampAnchorString(_ point: CGPoint) -> String {
        normalizedPointString(clampedStampAnchor(point))
    }

    static func normalizedStampAnchorString(x: Double, y: Double) -> String {
        normalizedStampAnchorString(CGPoint(x: x, y: y))
    }
}
