import SwiftUI

extension FloatingScratchBoard {
    // MARK: 面板手势

    func moveGesture(in availableSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .updating($moveTranslation) { value, state, _ in state = value.translation }
            .onEnded { value in
                panelCenter = ScratchBoardPanelGeometry.committedMoveCenter(
                    panelSize: panelSize,
                    panelCenter: panelCenter,
                    moveTranslation: value.translation,
                    availableSize: availableSize
                )
            }
    }

    func resizeGesture(in availableSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .updating($resizeTranslation) { value, state, _ in state = value.translation }
            .onEnded { value in
                let layout = ScratchBoardPanelGeometry.committedResizeLayout(
                    panelSize: panelSize,
                    panelCenter: panelCenter,
                    resizeTranslation: value.translation,
                    availableSize: availableSize
                )
                panelSize = layout.size
                panelCenter = layout.center
            }
    }

    func effectiveSize(in availableSize: CGSize) -> CGSize {
        ScratchBoardPanelGeometry.effectiveSize(
            panelSize: panelSize,
            resizeTranslation: resizeTranslation,
            availableSize: availableSize
        )
    }

    func effectiveCenter(panelSize displayedSize: CGSize, in availableSize: CGSize) -> CGPoint {
        ScratchBoardPanelGeometry.effectiveCenter(
            panelSize: panelSize,
            panelCenter: panelCenter,
            moveTranslation: moveTranslation,
            displayedSize: displayedSize,
            availableSize: availableSize
        )
    }

    func defaultCenter(in availableSize: CGSize) -> CGPoint {
        ScratchBoardPanelGeometry.defaultCenter(in: availableSize)
    }

    func constrainedSize(_ size: CGSize, in availableSize: CGSize) -> CGSize {
        ScratchBoardPanelGeometry.constrainedSize(size, in: availableSize)
    }

    func constrainedCenter(_ center: CGPoint, panelSize: CGSize, in availableSize: CGSize) -> CGPoint {
        ScratchBoardPanelGeometry.constrainedCenter(
            center,
            panelSize: panelSize,
            in: availableSize
        )
    }

    func updatePanelLayout(in availableSize: CGSize) {
        let nextSize = constrainedSize(panelSize, in: availableSize)
        if panelSize != nextSize {
            panelSize = nextSize
        }

        let nextCenter = constrainedCenter(
            panelCenter ?? defaultCenter(in: availableSize),
            panelSize: nextSize,
            in: availableSize
        )
        if panelCenter != nextCenter {
            panelCenter = nextCenter
        }
    }
}
