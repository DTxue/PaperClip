import SwiftUI

extension GeoCanvasRenderer {
    func renderPreview(ctx: inout GraphicsContext) {
        let staged = interactionState.stagedPositions
        let previewShading = GraphicsContext.Shading.color(shapeStyle.color.opacity(0.5))
        let dashed = StrokeStyle(lineWidth: shapeStyle.lineWidth, dash: [5, 3])

        renderStagedPoints(staged, ctx: &ctx)
        guard let preview = interactionState.previewPos else { return }

        if let path = ScratchBoardPreviewPath.path(
            tool: currentTool,
            staged: staged,
            preview: preview
        ) {
            ctx.stroke(path, with: previewShading, style: dashed)
        }

        var cursor = Path()
        cursor.addEllipse(in: CGRect(x: preview.x - 6, y: preview.y - 6, width: 12, height: 12))
        ctx.fill(cursor, with: .color(.white.opacity(0.8)))
        ctx.stroke(cursor, with: .color(shapeStyle.color.opacity(0.85)), lineWidth: 2)
    }

    func renderStagedPoints(_ staged: [CGPoint], ctx: inout GraphicsContext) {
        for (index, point) in staged.enumerated() {
            var halo = Path()
            halo.addEllipse(in: CGRect(x: point.x - 8, y: point.y - 8, width: 16, height: 16))
            ctx.fill(halo, with: .color(.white.opacity(0.95)))
            ctx.stroke(halo, with: .color(shapeStyle.color.opacity(0.9)), lineWidth: 2)

            var dot = Path()
            dot.addEllipse(in: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8))
            ctx.fill(dot, with: .color(shapeStyle.color))

            ctx.draw(
                Text("\(index + 1)")
                    .font(.system(size: 10, weight: .bold).monospacedDigit())
                    .foregroundStyle(Color.black),
                at: CGPoint(x: point.x + 10, y: point.y - 10),
                anchor: .bottomLeading
            )
        }
    }

    func renderSnapIndicator(ctx: inout GraphicsContext) {
        guard let snap = snapResult else { return }
        let pos = snap.position
        switch snap.kind {
        case .point:
            var ring = Path()
            ring.addEllipse(in: CGRect(x: pos.x - 11, y: pos.y - 11, width: 22, height: 22))
            ctx.stroke(ring, with: .color(.yellow.opacity(0.85)), lineWidth: 2)

        case .line:
            var diamond = Path()
            diamond.move(to: CGPoint(x: pos.x, y: pos.y - 8))
            diamond.addLine(to: CGPoint(x: pos.x + 8, y: pos.y))
            diamond.addLine(to: CGPoint(x: pos.x, y: pos.y + 8))
            diamond.addLine(to: CGPoint(x: pos.x - 8, y: pos.y))
            diamond.closeSubpath()
            ctx.stroke(diamond, with: .color(.green.opacity(0.9)), lineWidth: 2)

        case .grid:
            var cross = Path()
            cross.move(to: CGPoint(x: pos.x - 6, y: pos.y))
            cross.addLine(to: CGPoint(x: pos.x + 6, y: pos.y))
            cross.move(to: CGPoint(x: pos.x, y: pos.y - 6))
            cross.addLine(to: CGPoint(x: pos.x, y: pos.y + 6))
            ctx.stroke(cross, with: .color(.blue.opacity(0.55)), lineWidth: 1.5)

        case .none:
            break
        }
    }
}
