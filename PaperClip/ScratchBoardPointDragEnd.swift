import SwiftUI

extension FloatingScratchBoard {
    func finishPointDragIfNeeded() -> Bool {
        guard case .draggingPoint = interactionState else { return false }
        if let snapshot = dragSnapshot {
            if canvas.points != snapshot.points {
                recordUndo(snapshot)
                redoStack.removeAll()
            } else {
                canvas = snapshot
            }
            dragSnapshot = nil
        }
        resetGeometryInteraction()
        return true
    }
}
