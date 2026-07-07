import CoreGraphics

enum WritingFullscreenPaperViewport {
    static func expandedPaperWidth(currentWidth: Double, visibleWidth: CGFloat) -> Double? {
        let targetWidth = min(
            WritingPaperMetrics.maxWidth,
            max(WritingPaperMetrics.minWidth, Double(visibleWidth - 32))
        )
        return currentWidth < targetWidth ? targetWidth : nil
    }
}
