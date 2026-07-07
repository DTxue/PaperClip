import SwiftUI

extension GeoCanvasRenderer {
    func renderSelectionHandles(
        points: [CGPoint],
        shading: GraphicsContext.Shading,
        ctx: inout GraphicsContext
    ) {
        for pos in points {
            var handle = Path()
            handle.addRect(CGRect(x: pos.x - 4, y: pos.y - 4, width: 8, height: 8))
            ctx.fill(handle, with: .color(.white))
            ctx.stroke(handle, with: shading, lineWidth: 1.5)
        }
    }

    func renderSegmentMeasure(_ p1: CGPoint, _ p2: CGPoint, ctx: inout GraphicsContext) {
        let len = hypot(p2.x - p1.x, p2.y - p1.y) / gridSpacing
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        let d = hypot(dx, dy)
        guard d > 0 else { return }
        let nx = -dy / d
        let ny = dx / d
        let mid = CGPoint(x: (p1.x + p2.x) / 2 + nx * 13, y: (p1.y + p2.y) / 2 + ny * 13)
        ctx.draw(
            Text(String(format: "%.1f", len))
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(Color.secondary),
            at: mid,
            anchor: .center
        )
    }

    func renderCircleMeasure(center: CGPoint, rim: CGPoint, ctx: inout GraphicsContext) {
        let r = hypot(rim.x - center.x, rim.y - center.y) / gridSpacing
        ctx.draw(
            Text("r=\(String(format: "%.1f", r))")
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(Color.secondary),
            at: CGPoint(x: rim.x + 6, y: rim.y - 6),
            anchor: .bottomLeading
        )
    }

    func renderPoints(ctx: inout GraphicsContext) {
        for point in canvas.points {
            let isSelected = selectedIDs.contains(point.id)
            let pos = point.position
            let r: CGFloat = isSelected ? 6 : 5

            var halo = Path()
            halo.addEllipse(
                in: CGRect(
                    x: pos.x - r - 2,
                    y: pos.y - r - 2,
                    width: (r + 2) * 2,
                    height: (r + 2) * 2
                )
            )
            ctx.fill(halo, with: .color(.white.opacity(0.95)))
            ctx.stroke(halo, with: .color(.black.opacity(0.22)), lineWidth: 1)

            var dot = Path()
            dot.addEllipse(in: CGRect(x: pos.x - r, y: pos.y - r, width: r * 2, height: r * 2))
            ctx.fill(dot, with: .color(isSelected ? .orange : .blue))

            if isSelected {
                var ring = Path()
                ring.addEllipse(in: CGRect(x: pos.x - 9, y: pos.y - 9, width: 18, height: 18))
                ctx.stroke(ring, with: .color(.orange), lineWidth: 1.5)
            }

            if !point.label.isEmpty {
                ctx.draw(
                    Text(point.label)
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundStyle(Color.black),
                    at: CGPoint(x: pos.x + 7, y: pos.y - 7),
                    anchor: .bottomLeading
                )
            }
        }
    }
}
