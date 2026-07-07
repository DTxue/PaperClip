import CoreGraphics

enum ScratchBoardViewportLogic {
    static func pannedOrigin(
        startOrigin: CGPoint,
        translation: CGSize,
        limit: CGFloat
    ) -> CGPoint {
        constrainedOrigin(
            CGPoint(
                x: startOrigin.x - translation.width,
                y: startOrigin.y - translation.height
            ),
            limit: limit
        )
    }

    static func constrainedOrigin(
        _ origin: CGPoint,
        limit: CGFloat
    ) -> CGPoint {
        CGPoint(
            x: min(max(origin.x, -limit), limit),
            y: min(max(origin.y, -limit), limit)
        )
    }

    static func isTap(
        translation: CGSize,
        threshold: CGFloat = 8
    ) -> Bool {
        hypot(translation.width, translation.height) < threshold
    }
}
