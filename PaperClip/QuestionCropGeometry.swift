import CoreGraphics
import Foundation

enum CropDragState {
    case idle
    case movingBody
    case resizingTopLeft
    case resizingTopRight
    case resizingBottomLeft
    case resizingBottomRight
}

struct CropDragSession: Equatable {
    let state: CropDragState
    let startRect: CGRect
    let startPoint: CGPoint

    static let idle = CropDragSession(
        state: .idle,
        startRect: .zero,
        startPoint: .zero
    )

    func normalizedDelta(to point: CGPoint, in frame: CGRect) -> CGSize {
        guard frame.width > 0, frame.height > 0 else { return .zero }
        return CGSize(
            width: (point.x - startPoint.x) / frame.width,
            height: (point.y - startPoint.y) / frame.height
        )
    }

    func updatedRect(to point: CGPoint, in frame: CGRect) -> CGRect {
        let delta = normalizedDelta(to: point, in: frame)
        return switch state {
        case .movingBody:
            startRect.moved(by: delta)
        case .resizingTopLeft, .resizingTopRight, .resizingBottomLeft, .resizingBottomRight:
            startRect.resized(by: delta, dragState: state)
        case .idle:
            startRect
        }
    }
}

enum NormalizedCropGeometry {
    static let minimumSize: CGFloat = 0.05
    static let defaultRect = CGRect(x: 0.05, y: 0.05, width: 0.9, height: 0.9)

    static func initialRect(from cropString: String?) -> CGRect {
        guard let cropString, let rect = NormalizedCropString.parse(cropString) else {
            return defaultRect
        }
        return rect.clampedNormalized()
    }

    static func fittedFrame(imageSize: CGSize, viewSize: CGSize) -> CGRect {
        guard imageSize.width > 0,
              imageSize.height > 0,
              viewSize.width > 0,
              viewSize.height > 0
        else { return .zero }

        let imageRatio = imageSize.width / imageSize.height
        let viewRatio = viewSize.width / viewSize.height
        let size: CGSize = imageRatio > viewRatio
            ? CGSize(width: viewSize.width, height: viewSize.width / imageRatio)
            : CGSize(width: viewSize.height * imageRatio, height: viewSize.height)
        return CGRect(
            x: (viewSize.width - size.width) / 2,
            y: (viewSize.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }
}
