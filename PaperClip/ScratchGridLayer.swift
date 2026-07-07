import SwiftUI

// SwiftUI Canvas 是官方推荐的自定义 2D 绘制 API，无 UIKit 包装，
// 支持深色模式（Color.primary）和任意尺寸缩放。
struct ScratchGridLayer: View {
    let style: ScratchGridStyle
    let spacing: CGFloat
    let viewportOrigin: CGPoint

    var body: some View {
        GeometryReader { geo in
            Canvas { context, _ in
                let size = geo.size
                switch style {
                case .none: break
                case .square: drawSquare(context: context, size: size)
                case .dot: drawDot(context: context, size: size)
                }
            }
        }
    }

    private func drawSquare(context: GraphicsContext, size: CGSize) {
        var path = Path()
        var x = firstGridPosition(for: viewportOrigin.x)
        while x < size.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            x += spacing
        }

        var y = firstGridPosition(for: viewportOrigin.y)
        while y < size.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            y += spacing
        }

        context.stroke(path, with: .color(.init(white: 0, opacity: 0.18)), lineWidth: 0.5)
    }

    private func drawDot(context: GraphicsContext, size: CGSize) {
        var path = Path()
        var x = firstGridPosition(for: viewportOrigin.x)
        while x < size.width {
            var y = firstGridPosition(for: viewportOrigin.y)
            while y < size.height {
                path.addEllipse(in: CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3))
                y += spacing
            }
            x += spacing
        }
        context.fill(path, with: .color(.init(white: 0, opacity: 0.3)))
    }

    private func firstGridPosition(for origin: CGFloat) -> CGFloat {
        var position = (-origin).truncatingRemainder(dividingBy: spacing)
        if position <= 0 { position += spacing }
        return position
    }
}
