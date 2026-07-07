import CoreGraphics
import Foundation

enum ScratchBoardPanelGeometry {
    static let edgeInset: CGFloat = 12
    static let minimumSize = CGSize(width: 280, height: 200)

    struct Layout: Equatable {
        let size: CGSize
        let center: CGPoint
    }

    static func defaultCenter(in availableSize: CGSize) -> CGPoint {
        CGPoint(x: availableSize.width * 0.68, y: availableSize.height * 0.34)
    }

    static func constrainedSize(_ size: CGSize, in availableSize: CGSize) -> CGSize {
        CGSize(
            width: min(max(size.width, minimumSize.width), max(minimumSize.width, availableSize.width - edgeInset * 2)),
            height: min(max(size.height, minimumSize.height), max(minimumSize.height, availableSize.height - edgeInset * 2))
        )
    }

    static func constrainedCenter(
        _ center: CGPoint,
        panelSize: CGSize,
        in availableSize: CGSize
    ) -> CGPoint {
        CGPoint(
            x: clampedCenterCoordinate(
                center.x,
                panelLength: panelSize.width,
                availableLength: availableSize.width
            ),
            y: clampedCenterCoordinate(
                center.y,
                panelLength: panelSize.height,
                availableLength: availableSize.height
            )
        )
    }

    static func effectiveSize(
        panelSize: CGSize,
        resizeTranslation: CGSize,
        availableSize: CGSize
    ) -> CGSize {
        constrainedSize(
            CGSize(
                width: panelSize.width + resizeTranslation.width,
                height: panelSize.height + resizeTranslation.height
            ),
            in: availableSize
        )
    }

    static func effectiveCenter(
        panelSize: CGSize,
        panelCenter: CGPoint?,
        moveTranslation: CGSize,
        displayedSize: CGSize,
        availableSize: CGSize
    ) -> CGPoint {
        let baseCenter = panelCenter ?? defaultCenter(in: availableSize)
        return constrainedCenter(
            CGPoint(
                x: baseCenter.x + moveTranslation.width + (displayedSize.width - panelSize.width) / 2,
                y: baseCenter.y + moveTranslation.height + (displayedSize.height - panelSize.height) / 2
            ),
            panelSize: displayedSize,
            in: availableSize
        )
    }

    static func committedMoveCenter(
        panelSize: CGSize,
        panelCenter: CGPoint?,
        moveTranslation: CGSize,
        availableSize: CGSize
    ) -> CGPoint {
        let baseCenter = panelCenter ?? defaultCenter(in: availableSize)
        let displayedSize = constrainedSize(panelSize, in: availableSize)
        return constrainedCenter(
            CGPoint(
                x: baseCenter.x + moveTranslation.width,
                y: baseCenter.y + moveTranslation.height
            ),
            panelSize: displayedSize,
            in: availableSize
        )
    }

    static func committedResizeLayout(
        panelSize: CGSize,
        panelCenter: CGPoint?,
        resizeTranslation: CGSize,
        availableSize: CGSize
    ) -> Layout {
        let baseCenter = panelCenter ?? defaultCenter(in: availableSize)
        let nextSize = effectiveSize(
            panelSize: panelSize,
            resizeTranslation: resizeTranslation,
            availableSize: availableSize
        )
        let delta = CGSize(
            width: nextSize.width - panelSize.width,
            height: nextSize.height - panelSize.height
        )
        let nextCenter = constrainedCenter(
            CGPoint(
                x: baseCenter.x + delta.width / 2,
                y: baseCenter.y + delta.height / 2
            ),
            panelSize: nextSize,
            in: availableSize
        )
        return Layout(size: nextSize, center: nextCenter)
    }

    private static func clampedCenterCoordinate(
        _ value: CGFloat,
        panelLength: CGFloat,
        availableLength: CGFloat
    ) -> CGFloat {
        let lowerBound = panelLength / 2 + edgeInset
        let upperBound = availableLength - panelLength / 2 - edgeInset
        guard lowerBound <= upperBound else {
            return availableLength / 2
        }
        return min(max(value, lowerBound), upperBound)
    }
}
