import CoreGraphics
import Foundation

extension CGRect {
    func rect(in imageFrame: CGRect) -> CGRect {
        CGRect(
            x: imageFrame.minX + minX * imageFrame.width,
            y: imageFrame.minY + minY * imageFrame.height,
            width: width * imageFrame.width,
            height: height * imageFrame.height
        )
    }

    func clampedNormalized(minimumSize: CGFloat = NormalizedCropGeometry.minimumSize) -> CGRect {
        let x = min(max(minX, 0), 1 - minimumSize)
        let y = min(max(minY, 0), 1 - minimumSize)
        let w = max(min(width, 1 - x), minimumSize)
        let h = max(min(height, 1 - y), minimumSize)
        return CGRect(x: x, y: y, width: w, height: h)
    }

    func moved(by delta: CGSize) -> CGRect {
        CGRect(
            x: minX + delta.width,
            y: minY + delta.height,
            width: width,
            height: height
        ).clampedNormalized()
    }

    func resized(by delta: CGSize, dragState: CropDragState) -> CGRect {
        let newRect: CGRect
        switch dragState {
        case .resizingTopLeft:
            newRect = CGRect(x: minX + delta.width, y: minY + delta.height, width: width - delta.width, height: height - delta.height)
        case .resizingTopRight:
            newRect = CGRect(x: minX, y: minY + delta.height, width: width + delta.width, height: height - delta.height)
        case .resizingBottomLeft:
            newRect = CGRect(x: minX + delta.width, y: minY, width: width - delta.width, height: height + delta.height)
        case .resizingBottomRight:
            newRect = CGRect(x: minX, y: minY, width: width + delta.width, height: height + delta.height)
        case .idle, .movingBody:
            newRect = self
        }
        return newRect.clampedNormalized()
    }
}
