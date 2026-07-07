import SwiftUI
import PencilKit

extension FloatingScratchBoard {
    var body: some View {
        GeometryReader { geometry in
            let availableSize = geometry.size
            let displayedSize = effectiveSize(in: availableSize)
            let displayedCenter = effectiveCenter(panelSize: displayedSize, in: availableSize)

            VStack(spacing: 0) {
                ScratchBoardTitleBar(
                    showOpacitySlider: $showOpacitySlider,
                    backgroundOpacity: $backgroundOpacity,
                    isGeometricMode: $isGeometricMode,
                    moveGesture: moveGesture(in: availableSize),
                    clearHandwriting: clearHandwriting,
                    clearGeometry: clearGeometry,
                    clearAll: clearAll,
                    close: onClose
                )

                if isGeometricMode {
                    ScratchBoardGeometryToolbar(
                        currentTool: $currentTool,
                        shapeStyle: $shapeStyle,
                        isSnappingEnabled: $isSnappingEnabled,
                        snapToExistingPoints: $snapToExistingPoints,
                        snapToExistingLines: $snapToExistingLines,
                        snapToGrid: $snapToGrid,
                        bypassSnapOnce: $bypassSnapOnce,
                        gridStyle: $gridStyle,
                        viewportOrigin: $viewportOrigin,
                        selectedLetter: $selectedLetter,
                        canUndo: !undoStack.isEmpty,
                        canRedo: !redoStack.isEmpty,
                        undo: undo,
                        redo: redo,
                        snapModeChanged: { snapResult = nil }
                    )
                }

                ScratchBoardCanvasArea(
                    handwriting: $handwriting,
                    viewportOrigin: $viewportOrigin,
                    clearToken: clearToken,
                    backgroundOpacity: backgroundOpacity,
                    gridStyle: gridStyle,
                    gridSpacing: gridSpacing,
                    virtualCanvasOrigin: virtualCanvasOrigin,
                    virtualCanvasSize: virtualCanvasSize,
                    canvas: canvas,
                    selectedIDs: selectedIDs,
                    interactionState: interactionState,
                    snapResult: snapResult,
                    currentTool: currentTool,
                    shapeStyle: shapeStyle,
                    isGeometricMode: isGeometricMode,
                    resizeGesture: resizeGesture(in: availableSize),
                    handleGestureStart: handleGestureStart,
                    handleGestureMove: handleGestureMove,
                    handleGestureEnd: handleGestureEnd,
                    cancelCurrentConstruction: cancelCurrentConstruction,
                    deleteSelected: deleteSelected
                )
            }
            .frame(width: displayedSize.width, height: displayedSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.quaternary, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
            .position(displayedCenter)
            .transaction { $0.animation = nil }
            .onAppear {
                updatePanelLayout(in: availableSize)
            }
            .onChange(of: availableSize) { _, newSize in
                updatePanelLayout(in: newSize)
            }
            .onChange(of: currentTool) { _, _ in
                resetGeometryInteraction()
            }
            .onChange(of: isGeometricMode) { _, isOn in
                applyGeometricMode(isOn)
            }
        }
    }
}
