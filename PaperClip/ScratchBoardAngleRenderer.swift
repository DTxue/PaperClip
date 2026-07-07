import SwiftUI

extension GeoCanvasRenderer {
    func renderAngleMark(
        points pp: [CGPoint],
        isSelected: Bool,
        style: GeoStyle,
        shading: GraphicsContext.Shading,
        lineWidth: CGFloat,
        ctx: inout GraphicsContext
    ) {
        guard pp.count >= 3 else { return }
        let arm1 = pp[0]
        let vertex = pp[1]
        let arm2 = pp[2]
        var path = Path()
        path.move(to: arm1)
        path.addLine(to: vertex)
        path.move(to: arm2)
        path.addLine(to: vertex)
        ctx.stroke(path, with: shading, lineWidth: lineWidth)

        let r1 = hypot(arm1.x - vertex.x, arm1.y - vertex.y)
        let r2 = hypot(arm2.x - vertex.x, arm2.y - vertex.y)
        let arcRadius = min(r1, r2) * 0.35
        guard arcRadius > 4 else { return }

        let a1 = atan2(arm1.y - vertex.y, arm1.x - vertex.x)
        let a2 = atan2(arm2.y - vertex.y, arm2.x - vertex.x)
        var sweep = a2 - a1
        while sweep > .pi { sweep -= 2 * .pi }
        while sweep <= -.pi { sweep += 2 * .pi }

        var arcPath = Path()
        arcPath.addArc(
            center: vertex,
            radius: arcRadius,
            startAngle: .radians(a1),
            endAngle: .radians(a2),
            clockwise: sweep < 0
        )
        ctx.stroke(arcPath, with: shading, lineWidth: lineWidth)

        guard isSelected else { return }
        let degrees = abs(sweep) * 180 / .pi
        let midAngle = a1 + sweep / 2
        let labelPoint = CGPoint(
            x: vertex.x + (arcRadius + 10) * cos(midAngle),
            y: vertex.y + (arcRadius + 10) * sin(midAngle)
        )
        ctx.draw(
            Text("\(Int(degrees.rounded()))°")
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(style.color),
            at: labelPoint,
            anchor: .center
        )
    }
}
