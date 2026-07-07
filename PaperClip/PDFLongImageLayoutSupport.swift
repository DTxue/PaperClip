import CoreGraphics

struct PDFLongImagePageLayout: Equatable {
    let index: Int
    let sourceSize: CGSize
    let outputSize: CGSize

    var aspectRatio: CGFloat {
        sourceSize.height / sourceSize.width
    }
}

struct PDFLongImagePageFrame: Equatable {
    let index: Int
    let sourceSize: CGSize
    let outputSize: CGSize
    let destination: CGRect
}

struct PDFLongImageStackLayout: Equatable {
    let outputSize: CGSize
    let pages: [PDFLongImagePageFrame]
}

struct PDFLongImageConstrainedStackLayout: Equatable {
    let targetPixelWidth: CGFloat
    let stackLayout: PDFLongImageStackLayout
}

enum PDFLongImageLayoutSupport {
    static func constrainedWidth(
        preferredWidth: CGFloat,
        minimumWidth: CGFloat,
        maximumHeight: CGFloat,
        maximumPixelCount: CGFloat,
        totalAspectRatio: CGFloat,
        reservedHeight: CGFloat = 0
    ) -> CGFloat? {
        guard totalAspectRatio > 0 else { return nil }
        let availableHeight = maximumHeight - reservedHeight
        guard availableHeight > 0 else { return nil }
        let widthByHeight = availableHeight / totalAspectRatio
        let widthByPixels = sqrt(maximumPixelCount / totalAspectRatio)
        let width = floor(min(preferredWidth, widthByHeight, widthByPixels))
        return width >= minimumWidth ? width : nil
    }

    static func pageLayouts(
        pageInputs: [(index: Int, sourceSize: CGSize)],
        outputWidth: CGFloat
    ) -> [PDFLongImagePageLayout] {
        guard outputWidth > 0 else { return [] }

        return pageInputs.compactMap { input in
            outputSize(sourceSize: input.sourceSize, outputWidth: outputWidth).map {
                PDFLongImagePageLayout(
                    index: input.index,
                    sourceSize: input.sourceSize,
                    outputSize: $0
                )
            }
        }
    }

    private static func sourceAspectRatio(_ sourceSize: CGSize) -> CGFloat? {
        guard sourceSize.width > 0, sourceSize.height > 0 else { return nil }
        return sourceSize.height / sourceSize.width
    }

    static func outputSize(
        sourceSize: CGSize,
        outputWidth: CGFloat
    ) -> CGSize? {
        guard sourceSize.width > 0,
              sourceSize.height > 0,
              outputWidth > 0
        else { return nil }

        return CGSize(
            width: outputWidth,
            height: outputWidth * sourceSize.height / sourceSize.width
        )
    }

    static func totalAspectRatio(_ layouts: [PDFLongImagePageLayout]) -> CGFloat {
        layouts.reduce(CGFloat.zero) { $0 + $1.aspectRatio }
    }

    static func totalAspectRatio(pageInputs: [(index: Int, sourceSize: CGSize)]) -> CGFloat {
        pageInputs.reduce(CGFloat.zero) { partial, input in
            partial + (sourceAspectRatio(input.sourceSize) ?? 0)
        }
    }

    static func drawingImageScale(outputPixelWidth: CGFloat, canvasWidth: CGFloat) -> CGFloat {
        guard outputPixelWidth > 0, canvasWidth > 0 else { return 1 }
        return outputPixelWidth / canvasWidth
    }
}
