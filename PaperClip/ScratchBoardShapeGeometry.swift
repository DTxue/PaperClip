import SwiftUI

enum GeoShapeGeometry {
    static func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    static func distanceSquared(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return dx * dx + dy * dy
    }

    static func distanceToSegment(_ point: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let projected = projectedPoint(point, onSegmentFrom: a, to: b)
        return distance(point, projected)
    }

    static func isPoint(
        _ point: CGPoint,
        within threshold: CGFloat,
        ofSegmentFrom a: CGPoint,
        to b: CGPoint
    ) -> Bool {
        distanceToSegment(point, a, b) < threshold
    }

    static func isPoint(
        _ point: CGPoint,
        within threshold: CGFloat,
        ofCircleCenter center: CGPoint,
        rim: CGPoint
    ) -> Bool {
        let radius = distance(rim, center)
        let distanceToCenter = distance(point, center)
        return abs(distanceToCenter - radius) < threshold
    }

    static func projectedPoint(_ point: CGPoint, onSegmentFrom a: CGPoint, to b: CGPoint) -> CGPoint {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let squaredLength = dx * dx + dy * dy
        guard squaredLength > 0 else { return a }
        let t = max(0, min(1, ((point.x - a.x) * dx + (point.y - a.y) * dy) / squaredLength))
        return CGPoint(x: a.x + t * dx, y: a.y + t * dy)
    }

    static func circlePoint(nearestTo point: CGPoint, center: CGPoint, rim: CGPoint) -> CGPoint? {
        let radius = distance(rim, center)
        let distanceToCenter = distance(point, center)
        guard radius > 0, distanceToCenter > 0 else { return nil }
        return CGPoint(
            x: center.x + (point.x - center.x) / distanceToCenter * radius,
            y: center.y + (point.y - center.y) / distanceToCenter * radius
        )
    }
}
