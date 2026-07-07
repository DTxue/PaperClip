import SwiftUI

extension GeoCanvas {
    /// 返回距离触点最近的已有线条位置。包括线段、箭头、多边形边、角的两条边和圆周。
    func nearestLinePosition(
        to point: CGPoint,
        excludingPoint: UUID? = nil,
        threshold: CGFloat
    ) -> CGPoint? {
        guard !shapes.isEmpty else { return nil }

        let positionsByID = pointPositionsByID
        var bestPosition: CGPoint?
        var bestDistance = threshold

        func consider(_ candidate: CGPoint) {
            let distance = GeoShapeGeometry.distance(candidate, point)
            if distance < bestDistance {
                bestDistance = distance
                bestPosition = candidate
            }
        }

        func considerSegment(_ a: CGPoint, _ b: CGPoint) {
            consider(GeoShapeGeometry.projectedPoint(point, onSegmentFrom: a, to: b))
        }

        for shape in shapes {
            if let excludingPoint, shape.pointIDs.contains(excludingPoint) {
                continue
            }

            let positions = shape.pointIDs.compactMap { positionsByID[$0] }
            switch shape.kind {
            case .circle:
                guard positions.count >= 2,
                      let candidate = GeoShapeGeometry.circlePoint(
                          nearestTo: point,
                          center: positions[0],
                          rim: positions[1]
                      )
                else { continue }
                consider(candidate)
            default:
                shape.lineSegments(positions: positions).forEach { considerSegment($0.start, $0.end) }
            }
        }

        return bestPosition
    }

    func hitShape(at point: CGPoint, threshold: CGFloat = 14) -> UUID? {
        guard !shapes.isEmpty else { return nil }

        let positionsByID = pointPositionsByID
        for shape in shapes.reversed() {
            let positions = shape.pointIDs.compactMap { positionsByID[$0] }
            switch shape.kind {
            case .circle:
                guard positions.count >= 2,
                      GeoShapeGeometry.isPoint(point, within: threshold, ofCircleCenter: positions[0], rim: positions[1])
                else { continue }
                return shape.id
            default:
                let hit = shape.lineSegments(positions: positions).contains { segment in
                    GeoShapeGeometry.isPoint(
                        point,
                        within: threshold,
                        ofSegmentFrom: segment.start,
                        to: segment.end
                    )
                }
                if hit { return shape.id }
            }
        }
        return nil
    }
}

private extension GeoShape {
    func lineSegments(positions: [CGPoint]) -> [(start: CGPoint, end: CGPoint)] {
        switch kind {
        case .segment, .arrow:
            guard positions.count >= 2 else { return [] }
            return [(positions[0], positions[1])]
        case .polygon:
            guard positions.count >= 2 else { return [] }
            return positions.indices.map { (positions[$0], positions[($0 + 1) % positions.count]) }
        case .rightAngleMark, .angleMark:
            guard positions.count >= 3 else { return [] }
            return [(positions[0], positions[1]), (positions[1], positions[2])]
        case .circle:
            return []
        }
    }
}
