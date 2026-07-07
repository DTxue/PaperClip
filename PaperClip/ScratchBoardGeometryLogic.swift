import SwiftUI

extension FloatingScratchBoard {
    func handleGestureEnd(_ pt: CGPoint, isTap: Bool) {
        // 指针工具拖拽结束
        if finishPointDragIfNeeded() {
            return
        }

        guard isTap else {
            if case .staging(let positions, _) = interactionState {
                interactionState = .staging(positions: positions, preview: nil)
            }
            return
        }

        let modelPoint = modelPoint(from: pt)
        let snap = computeSnap(for: modelPoint)

        switch currentTool {
        case .pan:
            break

        case .pointer:
            break   // 选择在 gestureStart 完成

        case .point:
            if let pointID = snap.snapToPointID {
                selectedIDs = [pointID]
            } else {
                pushUndo()
                canvas.addPoint(at: snap.position)
            }
            resetGeometryInteraction()

        case .segment, .circle, .arrow:
            let staged = interactionState.stagedPositions
            if staged.isEmpty {
                interactionState = .staging(positions: [snap.position], preview: nil)
            } else {
                let second = snap.position
                guard hypot(staged[0].x - second.x, staged[0].y - second.y) > 4 else { break }
                pushUndo()
                let automaticallyLabelNewPoints = currentTool != .arrow
                let p1 = canvas.getOrCreatePoint(
                    near: staged[0],
                    automaticallyLabelNewPoint: automaticallyLabelNewPoints
                )
                let p2 = canvas.getOrCreatePoint(
                    near: second,
                    automaticallyLabelNewPoint: automaticallyLabelNewPoints
                )
                let kind: GeoShapeKind = currentTool == .circle ? .circle :
                                          currentTool == .arrow  ? .arrow  : .segment
                canvas.shapes.append(GeoShape(kind: kind, pointIDs: [p1.id, p2.id], style: shapeStyle))
                resetGeometryInteraction()
            }

        case .triangle, .rightAngle, .angleMark:
            var newStaged = interactionState.stagedPositions
            newStaged.append(snap.position)
            if newStaged.count < currentTool.requiredPoints {
                interactionState = .staging(positions: newStaged, preview: nil)
            } else {
                pushUndo()
                let automaticallyLabelNewPoints = currentTool == .triangle
                var pointIDs: [UUID] = []
                pointIDs.reserveCapacity(newStaged.count)
                for position in newStaged {
                    let point = canvas.getOrCreatePoint(
                        near: position,
                        automaticallyLabelNewPoint: automaticallyLabelNewPoints
                    )
                    pointIDs.append(point.id)
                }
                let kind: GeoShapeKind = currentTool == .triangle   ? .polygon :
                                          currentTool == .rightAngle ? .rightAngleMark : .angleMark
                canvas.shapes.append(GeoShape(kind: kind, pointIDs: pointIDs, style: shapeStyle))
                resetGeometryInteraction()
            }

        case .editLabel:
            if let point = editableLabelPoint(near: modelPoint),
               point.label != selectedLetter,
               let index = canvas.points.firstIndex(where: { $0.id == point.id }) {
                pushUndo()
                canvas.points[index].label = selectedLetter
                selectedIDs = [point.id]
            }
            resetGeometryInteraction()
        }

        if currentTool != .pointer && currentTool != .editLabel {
            bypassSnapOnce = false
        }
        snapResult = nil
    }

}
