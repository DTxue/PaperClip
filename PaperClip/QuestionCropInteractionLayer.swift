import SwiftUI

struct QuestionCropInteractionLayer: View {
    let selectionRect: CGRect
    let fittedFrame: CGRect
    @Binding var normRect: CGRect
    @Binding var dragSession: CropDragSession

    private let handleRadius: CGFloat = 16

    var body: some View {
        let minDimension = handleRadius * 3

        Color.white.opacity(0.001)
            .frame(
                width: max(selectionRect.width - handleRadius * 3, minDimension),
                height: max(selectionRect.height - handleRadius * 3, minDimension)
            )
            .position(x: selectionRect.midX, y: selectionRect.midY)
            .gesture(moveGesture())
            .accessibilityLabel("拖动移动选区")

        cornerHandle(at: CGPoint(x: selectionRect.minX, y: selectionRect.minY), state: .resizingTopLeft)
        cornerHandle(at: CGPoint(x: selectionRect.maxX, y: selectionRect.minY), state: .resizingTopRight)
        cornerHandle(at: CGPoint(x: selectionRect.minX, y: selectionRect.maxY), state: .resizingBottomLeft)
        cornerHandle(at: CGPoint(x: selectionRect.maxX, y: selectionRect.maxY), state: .resizingBottomRight)
    }

    private func cornerHandle(at point: CGPoint, state: CropDragState) -> some View {
        ZStack {
            Circle()
                .fill(Color.accentColor)
                .frame(width: handleRadius * 2, height: handleRadius * 2)
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: handleRadius * 2, height: handleRadius * 2)
        }
        .shadow(color: .black.opacity(0.3), radius: 3)
        .position(point)
        .gesture(resizeGesture(cornerState: state))
        .accessibilityLabel("调整选区角点")
    }

    private func moveGesture() -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                beginDragIfNeeded(.movingBody, at: value.startLocation)
                normRect = dragSession.updatedRect(to: value.location, in: fittedFrame)
            }
            .onEnded { _ in dragSession = .idle }
    }

    private func resizeGesture(cornerState: CropDragState) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                beginDragIfNeeded(cornerState, at: value.startLocation)
                normRect = dragSession.updatedRect(to: value.location, in: fittedFrame)
            }
            .onEnded { _ in dragSession = .idle }
    }

    private func beginDragIfNeeded(_ state: CropDragState, at startLocation: CGPoint) {
        guard dragSession.state != state else { return }
        dragSession = CropDragSession(
            state: state,
            startRect: normRect,
            startPoint: startLocation
        )
    }
}
