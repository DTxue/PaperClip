import CoreGraphics

struct PDFPageRenderScale: Equatable {
    let x: CGFloat
    let y: CGFloat
}

enum PDFPageRenderGeometry {
    static func pageScale(
        bounds: CGRect,
        destination: CGRect
    ) -> PDFPageRenderScale? {
        guard bounds.width > 0,
              bounds.height > 0,
              destination.width > 0,
              destination.height > 0
        else { return nil }

        return PDFPageRenderScale(
            x: destination.width / bounds.width,
            y: destination.height / bounds.height
        )
    }
}
