import SwiftUI

// MARK: - 几何图形渲染层
// 业务需求：点优先几何图形绘制。PencilKit 无预设形状 API。
// drawingPolicy = .pencilOnly 保证 Pencil 由 PK 处理，手指由此层处理。
// GeoPoint 是独立实体，图形通过 pointIDs 引用；渲染时动态解析坐标。

struct GeoCanvasLayer: View {
    let canvas: GeoCanvas
    let selectedIDs: Set<UUID>
    let interactionState: GeoInteractionState
    let snapResult: SnapResult?
    let currentTool: GeoDrawingTool
    let shapeStyle: GeoStyle
    let gridSpacing: CGFloat
    @Binding var viewportOrigin: CGPoint
    let isActive: Bool
    let onGestureStart: (CGPoint) -> Void
    let onGestureMove: (CGPoint) -> Void
    let onGestureEnd: (CGPoint, Bool) -> Void

    @State private var gestureActive = false
    @State private var panOriginAtStart: CGPoint?

    private let viewportLimit: CGFloat = 2_048

    var body: some View {
        Canvas { context, _ in
            context.translateBy(x: -viewportOrigin.x, y: -viewportOrigin.y)
            GeoCanvasRenderer(
                canvas: canvas,
                selectedIDs: selectedIDs,
                interactionState: interactionState,
                snapResult: snapResult,
                currentTool: currentTool,
                shapeStyle: shapeStyle,
                gridSpacing: gridSpacing
            )
            .render(ctx: &context)
        }
        .contentShape(Rectangle())
        .allowsHitTesting(isActive)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    if currentTool == .pan {
                        let startOrigin = panOriginAtStart ?? viewportOrigin
                        if panOriginAtStart == nil {
                            panOriginAtStart = viewportOrigin
                        }
                        viewportOrigin = ScratchBoardViewportLogic.pannedOrigin(
                            startOrigin: startOrigin,
                            translation: value.translation,
                            limit: viewportLimit
                        )
                        return
                    }

                    if !gestureActive {
                        gestureActive = true
                        onGestureStart(value.startLocation)
                    }
                    onGestureMove(value.location)
                }
                .onEnded { value in
                    if currentTool == .pan {
                        let startOrigin = panOriginAtStart ?? viewportOrigin
                        viewportOrigin = ScratchBoardViewportLogic.pannedOrigin(
                            startOrigin: startOrigin,
                            translation: value.translation,
                            limit: viewportLimit
                        )
                        panOriginAtStart = nil
                        gestureActive = false
                        return
                    }

                    onGestureEnd(
                        value.location,
                        ScratchBoardViewportLogic.isTap(translation: value.translation)
                    )
                    gestureActive = false
                },
            including: isActive ? .all : .none
        )
        .accessibilityLabel("几何绘图区域")
        .accessibilityHint(
            currentTool == .pan
                ? "单指拖动以移动画布"
                : "使用手指放置或移动控制点，Apple Pencil 用于手写"
        )
        .onChange(of: currentTool) { _, _ in
            panOriginAtStart = nil
            gestureActive = false
        }
    }
}
