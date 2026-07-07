import SwiftUI

enum ScratchBoardShapePaths {
    static func segment(from start: CGPoint, to end: CGPoint) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }

    static func arrow(from start: CGPoint, to end: CGPoint) -> Path {
        var path = segment(from: start, to: end)
        let length = GeoShapeGeometry.distance(start, end)
        guard length > 0 else { return path }

        let direction = CGPoint(
            x: (end.x - start.x) / length,
            y: (end.y - start.y) / length
        )
        let wingLength = min(CGFloat(16), length * 0.35)
        let angle: CGFloat = .pi / 6
        let cosine = cos(angle)
        let sine = sin(angle)

        path.move(to: end)
        path.addLine(to: CGPoint(
            x: end.x - wingLength * (direction.x * cosine - direction.y * sine),
            y: end.y - wingLength * (direction.y * cosine + direction.x * sine)
        ))
        path.move(to: end)
        path.addLine(to: CGPoint(
            x: end.x - wingLength * (direction.x * cosine + direction.y * sine),
            y: end.y - wingLength * (direction.y * cosine - direction.x * sine)
        ))
        return path
    }

    static func circle(center: CGPoint, rim: CGPoint) -> Path {
        let radius = GeoShapeGeometry.distance(center, rim)
        var path = Path()
        path.addEllipse(in: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        return path
    }

    static func polygon(points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        points.dropFirst().forEach { path.addLine(to: $0) }
        path.closeSubpath()
        return path
    }

    static func rightAngleArms(arm1: CGPoint, vertex: CGPoint, arm2: CGPoint) -> Path {
        var path = Path()
        path.move(to: arm1)
        path.addLine(to: vertex)
        path.move(to: arm2)
        path.addLine(to: vertex)
        return path
    }

    static func rightAngleSquare(arm1: CGPoint, vertex: CGPoint, arm2: CGPoint, size: CGFloat = 11) -> Path {
        let direction1 = normalizedVector(from: vertex, to: arm1)
        let direction2 = normalizedVector(from: vertex, to: arm2)
        var path = Path()
        path.move(to: CGPoint(
            x: vertex.x + direction1.x * size,
            y: vertex.y + direction1.y * size
        ))
        path.addLine(to: CGPoint(
            x: vertex.x + direction1.x * size + direction2.x * size,
            y: vertex.y + direction1.y * size + direction2.y * size
        ))
        path.addLine(to: CGPoint(
            x: vertex.x + direction2.x * size,
            y: vertex.y + direction2.y * size
        ))
        return path
    }

    private static func normalizedVector(from origin: CGPoint, to point: CGPoint) -> CGPoint {
        let dx = point.x - origin.x
        let dy = point.y - origin.y
        let length = hypot(dx, dy)
        guard length > 0 else { return .zero }
        return CGPoint(x: dx / length, y: dy / length)
    }
}
