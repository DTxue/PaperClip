import SwiftUI

struct GeoCanvasRenderer {
    let canvas: GeoCanvas
    let selectedIDs: Set<UUID>
    let interactionState: GeoInteractionState
    let snapResult: SnapResult?
    let currentTool: GeoDrawingTool
    let shapeStyle: GeoStyle
    let gridSpacing: CGFloat

    func render(ctx: inout GraphicsContext) {
        renderShapes(ctx: &ctx)
        renderPoints(ctx: &ctx)
        renderPreview(ctx: &ctx)
        renderSnapIndicator(ctx: &ctx)
    }

    private func renderShapes(ctx: inout GraphicsContext) {
        for shape in canvas.shapes {
            renderShape(shape, ctx: &ctx)
        }
    }

    private func renderShape(_ shape: GeoShape, ctx: inout GraphicsContext) {
        let isSelected = selectedIDs.contains(shape.id)
        let style = shape.style
        let lw = isSelected ? style.lineWidth + 1 : style.lineWidth
        let shading = GraphicsContext.Shading.color(style.color)
        let pp = shape.pointIDs.compactMap { canvas.point($0)?.position }

        switch shape.kind {
        case .segment:
            guard pp.count >= 2 else { return }
            ctx.stroke(ScratchBoardShapePaths.segment(from: pp[0], to: pp[1]), with: shading, lineWidth: lw)
            if isSelected { renderSegmentMeasure(pp[0], pp[1], ctx: &ctx) }

        case .arrow:
            guard pp.count >= 2 else { return }
            ctx.stroke(ScratchBoardShapePaths.arrow(from: pp[0], to: pp[1]), with: shading, lineWidth: lw)

        case .circle:
            guard pp.count >= 2 else { return }
            ctx.stroke(ScratchBoardShapePaths.circle(center: pp[0], rim: pp[1]), with: shading, lineWidth: lw)
            if isSelected { renderCircleMeasure(center: pp[0], rim: pp[1], ctx: &ctx) }

        case .polygon:
            guard pp.count >= 3 else { return }
            ctx.stroke(ScratchBoardShapePaths.polygon(points: pp), with: shading, lineWidth: lw)

        case .rightAngleMark:
            guard pp.count >= 3 else { return }
            let arm1 = pp[0]
            let vertex = pp[1]
            let arm2 = pp[2]
            ctx.stroke(ScratchBoardShapePaths.rightAngleArms(arm1: arm1, vertex: vertex, arm2: arm2), with: shading, lineWidth: lw)
            ctx.stroke(ScratchBoardShapePaths.rightAngleSquare(arm1: arm1, vertex: vertex, arm2: arm2), with: shading, lineWidth: lw)

        case .angleMark:
            renderAngleMark(points: pp, isSelected: isSelected, style: style, shading: shading, lineWidth: lw, ctx: &ctx)
        }

        if isSelected {
            renderSelectionHandles(points: pp, shading: shading, ctx: &ctx)
        }
    }
}
