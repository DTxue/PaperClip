import SwiftUI

extension FloatingScratchBoard {
    func computeSnap(for pt: CGPoint, excludingPoint: UUID? = nil) -> SnapResult {
        guard isSnappingEnabled, !bypassSnapOnce else {
            return SnapResult(position: pt, snapToPointID: nil, kind: .none)
        }

        if snapToExistingPoints,
           let nearest = nearestPoint(
               near: pt,
               threshold: pointSnapDistance,
               excludingPoint: excludingPoint,
               requireLabel: false
           ) {
            return SnapResult(position: nearest.position, snapToPointID: nearest.id, kind: .point)
        }

        if snapToExistingLines,
           let linePosition = canvas.nearestLinePosition(
               to: pt,
               excludingPoint: excludingPoint,
               threshold: lineSnapDistance
           ) {
            return SnapResult(position: linePosition, snapToPointID: nil, kind: .line)
        }

        if snapToGrid, gridStyle != .none {
            let snapped = CGPoint(
                x: round(pt.x / gridSpacing) * gridSpacing,
                y: round(pt.y / gridSpacing) * gridSpacing
            )
            if hypot(snapped.x - pt.x, snapped.y - pt.y) <= gridSnapDistance {
                return SnapResult(position: snapped, snapToPointID: nil, kind: .grid)
            }
        }

        return SnapResult(position: pt, snapToPointID: nil, kind: .none)
    }

    /// 字母工具只允许修改已有标签，不受绘图吸附设置影响。
    func editableLabelPoint(near pt: CGPoint) -> GeoPoint? {
        nearestPoint(
            near: pt,
            threshold: pointSnapDistance + 6,
            excludingPoint: nil,
            requireLabel: true
        )
    }

    func nearestPoint(
        near point: CGPoint,
        threshold: CGFloat,
        excludingPoint: UUID?,
        requireLabel: Bool
    ) -> GeoPoint? {
        canvas.nearestPoint(
            to: point,
            threshold: threshold,
            excludingPoint: excludingPoint,
            requireLabel: requireLabel
        )
    }
}
