import SwiftUI

extension FloatingScratchBoard {
    func modelPoint(from viewportPoint: CGPoint) -> CGPoint {
        CGPoint(
            x: viewportPoint.x + viewportOrigin.x,
            y: viewportPoint.y + viewportOrigin.y
        )
    }

    func handleGestureStart(_ pt: CGPoint) {
        let modelPoint = modelPoint(from: pt)

        if currentTool == .editLabel {
            if let point = editableLabelPoint(near: modelPoint) {
                snapResult = SnapResult(position: point.position, snapToPointID: point.id, kind: .point)
            } else {
                snapResult = nil
            }
            return
        }

        let snap = computeSnap(for: modelPoint)
        snapResult = snap

        switch currentTool {
        case .pointer:
            if let pid = snap.snapToPointID {
                selectedIDs = [pid]
                dragSnapshot = canvas
                interactionState = .draggingPoint(id: pid)
            } else if let sid = canvas.hitShape(at: modelPoint) {
                selectedIDs = [sid]
                interactionState = .idle
            } else {
                selectedIDs = []
                interactionState = .idle
            }
        default:
            break
        }
    }

    func handleGestureMove(_ pt: CGPoint) {
        let modelPoint = modelPoint(from: pt)

        if currentTool == .editLabel {
            if let point = editableLabelPoint(near: modelPoint) {
                snapResult = SnapResult(position: point.position, snapToPointID: point.id, kind: .point)
            } else {
                snapResult = nil
            }
            interactionState = .idle
            return
        }

        var excludeID: UUID? = nil
        if case .draggingPoint(let id) = interactionState { excludeID = id }

        let snap = computeSnap(for: modelPoint, excludingPoint: excludeID)
        snapResult = snap

        switch interactionState {
        case .draggingPoint(let id):
            if let idx = canvas.points.firstIndex(where: { $0.id == id }) {
                canvas.points[idx].position = snap.position
            }
        case .staging(let positions, _):
            interactionState = .staging(positions: positions, preview: snap.position)
        case .idle:
            if currentTool != .pointer {
                interactionState = .staging(positions: [], preview: snap.position)
            }
        }
    }
}
