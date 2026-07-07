import CoreGraphics

extension PDFLongImageLayoutSupport {
    static func stackedLayout(
        pageInputs: [(index: Int, sourceSize: CGSize)],
        outputWidth: CGFloat,
        pageGap: CGFloat = 0,
        roundsPageHeights: Bool = false
    ) -> PDFLongImageStackLayout? {
        guard outputWidth > 0, pageGap >= 0 else { return nil }
        let layouts = pageLayouts(pageInputs: pageInputs, outputWidth: outputWidth)
        guard !layouts.isEmpty else { return nil }

        var y: CGFloat = 0
        var pages: [PDFLongImagePageFrame] = []
        pages.reserveCapacity(layouts.count)
        for (offset, layout) in layouts.enumerated() {
            let height = roundsPageHeights ? ceil(layout.outputSize.height) : layout.outputSize.height
            let outputSize = CGSize(width: outputWidth, height: height)
            pages.append(
                PDFLongImagePageFrame(
                    index: layout.index,
                    sourceSize: layout.sourceSize,
                    outputSize: outputSize,
                    destination: CGRect(x: 0, y: y, width: outputWidth, height: height)
                )
            )
            y += height
            if offset < layouts.count - 1 {
                y += pageGap
            }
        }

        return PDFLongImageStackLayout(
            outputSize: CGSize(width: outputWidth, height: y),
            pages: pages
        )
    }

    static func constrainedStackLayout(
        pageInputs: [(index: Int, sourceSize: CGSize)],
        preferredPixelWidth: CGFloat,
        minimumPixelWidth: CGFloat,
        maximumPixelHeight: CGFloat,
        maximumPixelCount: CGFloat,
        outputScale: CGFloat = 1,
        reservedHeight: CGFloat = 0,
        pageGap: CGFloat = 0,
        roundsPageHeights: Bool = false
    ) -> PDFLongImageConstrainedStackLayout? {
        let safeScale = max(outputScale, 1)
        let totalAspectRatio = totalAspectRatio(pageInputs: pageInputs)
        guard let targetPixelWidth = constrainedWidth(
            preferredWidth: preferredPixelWidth,
            minimumWidth: minimumPixelWidth,
            maximumHeight: maximumPixelHeight,
            maximumPixelCount: maximumPixelCount,
            totalAspectRatio: totalAspectRatio,
            reservedHeight: reservedHeight
        ) else { return nil }

        guard let stackLayout = stackedLayout(
            pageInputs: pageInputs,
            outputWidth: targetPixelWidth / safeScale,
            pageGap: pageGap,
            roundsPageHeights: roundsPageHeights
        ) else { return nil }

        return PDFLongImageConstrainedStackLayout(
            targetPixelWidth: targetPixelWidth,
            stackLayout: stackLayout
        )
    }
}
