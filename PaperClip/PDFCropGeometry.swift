import CoreGraphics
import Foundation

enum PDFCropGeometry {
    static let minimumCropSize = CGSize(width: 8, height: 8)
    static let defaultRenderScale: CGFloat = 2

    static func boundedCrop(
        _ cropRect: CGRect,
        in pageBounds: CGRect,
        minimumSize: CGSize = minimumCropSize
    ) -> CGRect? {
        guard pageBounds.width > 0, pageBounds.height > 0 else { return nil }
        let boundedCrop = cropRect.standardized.intersection(pageBounds.standardized)
        guard boundedCrop.width > minimumSize.width,
              boundedCrop.height > minimumSize.height
        else { return nil }
        return boundedCrop
    }

    static func outputSize(
        for cropRect: CGRect,
        scale: CGFloat = defaultRenderScale
    ) -> CGSize? {
        guard cropRect.width > 0,
              cropRect.height > 0,
              scale > 0
        else { return nil }
        return CGSize(
            width: cropRect.width * scale,
            height: cropRect.height * scale
        )
    }
}
