import SwiftUI

extension GeoCanvas {
    private var usedLabels: Set<String> {
        var labels = Set<String>()
        labels.reserveCapacity(points.count)
        for point in points {
            labels.insert(point.label)
        }
        return labels
    }

    var pointPositionsByID: [UUID: CGPoint] {
        var positions: [UUID: CGPoint] = [:]
        positions.reserveCapacity(points.count)
        for point in points {
            positions[point.id] = point.position
        }
        return positions
    }

    mutating func nextLabel() -> String {
        let used = usedLabels
        for ch in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
            let label = String(ch)
            if !used.contains(label) { return label }
        }
        var n = 1
        while used.contains("P\(n)") { n += 1 }
        return "P\(n)"
    }

    @discardableResult
    mutating func addPoint(at position: CGPoint, automaticallyLabel: Bool = true) -> GeoPoint {
        let point = GeoPoint(position: position, label: automaticallyLabel ? nextLabel() : "")
        points.append(point)
        return point
    }

    /// 仅复用坐标实际重合的点。是否吸附由手势层决定，避免自由放置时因临近旧点而被隐式合并。
    @discardableResult
    mutating func getOrCreatePoint(
        near position: CGPoint,
        threshold: CGFloat = 1,
        automaticallyLabelNewPoint: Bool = true
    ) -> GeoPoint {
        if let existing = nearestPoint(to: position, threshold: threshold) { return existing }
        return addPoint(at: position, automaticallyLabel: automaticallyLabelNewPoint)
    }

    func nearestPoint(
        to position: CGPoint,
        threshold: CGFloat = 22,
        excludingPoint: UUID? = nil,
        requireLabel: Bool = false
    ) -> GeoPoint? {
        let thresholdSquared = threshold * threshold
        var nearest: GeoPoint?
        var nearestDistanceSquared = thresholdSquared

        for point in points {
            guard point.id != excludingPoint else { continue }
            guard !requireLabel || !point.label.isEmpty else { continue }

            let distanceSquared = GeoShapeGeometry.distanceSquared(point.position, position)
            guard distanceSquared < nearestDistanceSquared else { continue }

            nearest = point
            nearestDistanceSquared = distanceSquared
        }

        return nearest
    }

    mutating func delete(pointIDs delPIDs: Set<UUID>, shapeIDs delSIDs: Set<UUID>) {
        var cascade: Set<UUID> = []
        for shape in shapes where shape.pointIDs.contains(where: { delPIDs.contains($0) }) {
            cascade.insert(shape.id)
        }
        shapes.removeAll { delSIDs.contains($0.id) || cascade.contains($0.id) }
        points.removeAll { delPIDs.contains($0.id) }
    }
}
