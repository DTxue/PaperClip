import CoreGraphics

struct ReviewSubmissionPageGeometry: Equatable {
    let displayBounds: CGRect
    let drawingBounds: CGRect
}

enum ReviewSubmissionGeometry {
    static func pageGeometry(
        mediaBounds: CGRect,
        cropBounds: CGRect
    ) -> ReviewSubmissionPageGeometry? {
        let mediaBounds = mediaBounds.standardized
        let cropBounds = cropBounds.standardized
        let displayBounds = cropBounds.width > 0 && cropBounds.height > 0 ? cropBounds : mediaBounds

        guard mediaBounds.width > 0,
              mediaBounds.height > 0,
              displayBounds.width > 0,
              displayBounds.height > 0
        else { return nil }

        return ReviewSubmissionPageGeometry(
            displayBounds: displayBounds,
            drawingBounds: drawingBounds(
                mediaBounds: mediaBounds,
                displayBounds: displayBounds
            )
        )
    }

    static func drawingBounds(
        mediaBounds: CGRect,
        displayBounds: CGRect
    ) -> CGRect {
        CGRect(
            x: displayBounds.minX - mediaBounds.minX,
            y: mediaBounds.maxY - displayBounds.maxY,
            width: displayBounds.width,
            height: displayBounds.height
        )
    }
}
