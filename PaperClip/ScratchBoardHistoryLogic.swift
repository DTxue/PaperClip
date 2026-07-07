import PencilKit

extension FloatingScratchBoard {
    func resetGeometryInteraction(clearSelection: Bool = false) {
        interactionState = .idle
        snapResult = nil
        if clearSelection {
            selectedIDs = []
        }
    }

    func clearHandwriting() {
        handwriting = PKDrawing()
        clearToken += 1
    }

    func applyGeometricMode(_ isOn: Bool) {
        resetGeometryInteraction(clearSelection: !isOn)
        if isOn {
            if gridStyle == .none { gridStyle = .square }
        } else {
            bypassSnapOnce = false
            gridStyle = .none
        }
    }

    func recordUndo(_ snapshot: GeoCanvas) {
        undoStack.append(snapshot)
        if undoStack.count > 30 { undoStack.removeFirst() }
    }

    func pushUndo() {
        recordUndo(canvas)
        redoStack.removeAll()
    }

    func undo() {
        guard let prev = undoStack.popLast() else { return }
        redoStack.append(canvas)
        canvas = prev
        selectedIDs = []
        resetGeometryInteraction()
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(canvas)
        canvas = next
    }

    func deleteSelected() {
        guard !selectedIDs.isEmpty else { return }
        pushUndo()
        var pids: Set<UUID> = []
        var sids: Set<UUID> = []
        for point in canvas.points where selectedIDs.contains(point.id) {
            pids.insert(point.id)
        }
        for shape in canvas.shapes where selectedIDs.contains(shape.id) {
            sids.insert(shape.id)
        }
        canvas.delete(pointIDs: pids, shapeIDs: sids)
        selectedIDs = []
    }

    func clearGeometry() {
        guard !canvas.points.isEmpty || !canvas.shapes.isEmpty else { return }
        pushUndo()
        canvas = GeoCanvas()
        selectedIDs = []
        resetGeometryInteraction()
    }

    func clearAll() {
        clearHandwriting()
        clearGeometry()
    }

    func cancelCurrentConstruction() {
        resetGeometryInteraction()
    }
}
