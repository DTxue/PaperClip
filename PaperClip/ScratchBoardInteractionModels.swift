import SwiftUI

enum GeoInteractionState {
    case idle
    case draggingPoint(id: UUID)
    case staging(positions: [CGPoint], preview: CGPoint?)

    var stagedPositions: [CGPoint] {
        if case .staging(let positions, _) = self { return positions }
        return []
    }

    var previewPos: CGPoint? {
        if case .staging(_, let position) = self { return position }
        return nil
    }
}

enum GeoSnapKind {
    case none
    case point
    case line
    case grid
}

struct SnapResult {
    var position: CGPoint
    var snapToPointID: UUID?
    var kind: GeoSnapKind
}
