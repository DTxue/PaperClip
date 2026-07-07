import CoreGraphics
import Foundation

enum PDFSelectionHandleGeometry {
    static let hitRadius: CGFloat = 26

    static func handle(at point: CGPoint, in rect: CGRect) -> PDFSelectionHandle? {
        PDFSelectionHandle.allCases.first {
            let center = self.point(for: $0, in: rect)
            return hypot(point.x - center.x, point.y - center.y) <= hitRadius
        }
    }

    static func point(for handle: PDFSelectionHandle, in rect: CGRect) -> CGPoint {
        switch handle {
        case .topLeft: CGPoint(x: rect.minX, y: rect.minY)
        case .top: CGPoint(x: rect.midX, y: rect.minY)
        case .topRight: CGPoint(x: rect.maxX, y: rect.minY)
        case .right: CGPoint(x: rect.maxX, y: rect.midY)
        case .bottomRight: CGPoint(x: rect.maxX, y: rect.maxY)
        case .bottom: CGPoint(x: rect.midX, y: rect.maxY)
        case .bottomLeft: CGPoint(x: rect.minX, y: rect.maxY)
        case .left: CGPoint(x: rect.minX, y: rect.midY)
        }
    }
}
