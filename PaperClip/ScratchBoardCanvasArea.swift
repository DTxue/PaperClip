import SwiftUI
import PencilKit

struct ScratchBoardCanvasArea<ResizeGesture: Gesture>: View {
    @Binding var handwriting: PKDrawing
    @Binding var viewportOrigin: CGPoint

    let clearToken: Int
    let backgroundOpacity: Double
    let gridStyle: ScratchGridStyle
    let gridSpacing: CGFloat
    let virtualCanvasOrigin: CGPoint
    let virtualCanvasSize: CGSize
    let canvas: GeoCanvas
    let selectedIDs: Set<UUID>
    let interactionState: GeoInteractionState
    let snapResult: SnapResult?
    let currentTool: GeoDrawingTool
    let shapeStyle: GeoStyle
    let isGeometricMode: Bool
    let resizeGesture: ResizeGesture
    let handleGestureStart: (CGPoint) -> Void
    let handleGestureMove: (CGPoint) -> Void
    let handleGestureEnd: (CGPoint, Bool) -> Void
    let cancelCurrentConstruction: () -> Void
    let deleteSelected: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.white.opacity(backgroundOpacity)

            if gridStyle != .none {
                ScratchGridLayer(
                    style: gridStyle,
                    spacing: gridSpacing,
                    viewportOrigin: viewportOrigin
                )
                .opacity(0.5)
                .allowsHitTesting(false)
            }

            PencilDrawingCanvas(
                drawing: $handwriting,
                reloadToken: clearToken,
                accessibilityLabel: "草稿手写区域",
                toolAutosaveName: "PaperClip.ScratchTools",
                preferredTool: PKInkingTool(.pen, color: .systemBlue, width: 3),
                preferredToolID: "scratch-pen-blue-3",
                viewport: pencilViewport
            )
            .background(Color.clear)

            GeoCanvasLayer(
                canvas: canvas,
                selectedIDs: selectedIDs,
                interactionState: interactionState,
                snapResult: snapResult,
                currentTool: currentTool,
                shapeStyle: shapeStyle,
                gridSpacing: gridSpacing,
                viewportOrigin: $viewportOrigin,
                isActive: isGeometricMode,
                onGestureStart: handleGestureStart,
                onGestureMove: handleGestureMove,
                onGestureEnd: handleGestureEnd
            )

            ScratchBoardResizeHandle(resizeGesture: resizeGesture)
        }
        .overlay(alignment: .top) { statusOverlay }
    }

    private var pencilViewport: PencilCanvasViewport {
        PencilCanvasViewport(
            contentSize: virtualCanvasSize,
            contentOffset: CGPoint(
                x: virtualCanvasOrigin.x + viewportOrigin.x,
                y: virtualCanvasOrigin.y + viewportOrigin.y
            )
        )
    }

    private var statusOverlay: some View {
        ScratchBoardCanvasStatusOverlay(
            currentTool: currentTool,
            interactionState: interactionState,
            selectedIDs: selectedIDs,
            canvas: canvas,
            cancelCurrentConstruction: cancelCurrentConstruction,
            deleteSelected: deleteSelected
        )
    }
}
