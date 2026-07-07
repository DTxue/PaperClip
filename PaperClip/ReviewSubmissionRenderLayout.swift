import CoreGraphics

enum ReviewSubmissionRenderLayout {
    static let pageGap: CGFloat = 12

    private static let preferredWidth: CGFloat = 1_600
    private static let minimumWidth: CGFloat = 600
    private static let maximumHeight: CGFloat = 16_000
    private static let maximumPixelCount: CGFloat = 28_000_000

    static func outputLayout(for pageGeometries: [ReviewSubmissionPageGeometry]) -> PDFLongImageStackLayout? {
        var pageInputs: [(index: Int, sourceSize: CGSize)] = []
        pageInputs.reserveCapacity(pageGeometries.count)
        for index in pageGeometries.indices {
            pageInputs.append((index: index, sourceSize: pageGeometries[index].displayBounds.size))
        }

        let gapsHeight = pageGap * CGFloat(max(pageGeometries.count - 1, 0))
        return PDFLongImageLayoutSupport.constrainedStackLayout(
            pageInputs: pageInputs,
            preferredPixelWidth: preferredWidth,
            minimumPixelWidth: minimumWidth,
            maximumPixelHeight: maximumHeight,
            maximumPixelCount: maximumPixelCount,
            reservedHeight: gapsHeight,
            pageGap: pageGap,
            roundsPageHeights: true
        )?.stackLayout
    }
}
