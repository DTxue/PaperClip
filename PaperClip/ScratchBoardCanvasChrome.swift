import SwiftUI

struct ScratchBoardResizeHandle<ResizeGesture: Gesture>: View {
    let resizeGesture: ResizeGesture

    var body: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.secondary)
            .frame(width: 38, height: 38)
            .background(.regularMaterial, in: Circle())
            .contentShape(Rectangle())
            .padding(6)
            .gesture(resizeGesture)
            .accessibilityLabel("调整草稿板大小")
    }
}

struct ScratchBoardCanvasStatusOverlay: View {
    let currentTool: GeoDrawingTool
    let interactionState: GeoInteractionState
    let selectedIDs: Set<UUID>
    let canvas: GeoCanvas
    let cancelCurrentConstruction: () -> Void
    let deleteSelected: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ScratchBoardConstructionStatus(
                currentTool: currentTool,
                interactionState: interactionState,
                cancel: cancelCurrentConstruction
            )
            ScratchBoardSelectionStatus(
                currentTool: currentTool,
                selectedIDs: selectedIDs,
                canvas: canvas,
                deleteSelected: deleteSelected
            )
        }
        .padding(.top, 8)
    }
}
