import PencilKit
import SwiftUI

/// 写作纸背景用于承载横线/方格业务样式。Apple 提供表单、TextEditor 与 Canvas，
/// 但没有可与 PKDrawing 坐标一致的作文纸背景组件；这里仅绘制静态纸张线条，
/// 不替代系统输入、滚动、画笔或选择器，深色模式下也只调整背景与辅助线颜色。
struct WritingPaperBackground: View {
    let style: WritingPaperStyle
    let blackPaperMode: Bool
    let rulingSpacing: Double

    var body: some View {
        Canvas { context, size in
            let background = blackPaperMode ? Color.black : Color.white
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(background))

            let lineColor = blackPaperMode
                ? Color.white.opacity(0.22)
                : Color.gray.opacity(0.35)
            let spacing = CGFloat(WritingPaperMetrics.clampedRulingSpacing(rulingSpacing))

            var horizontal = Path()
            var y = spacing
            while y < size.height {
                horizontal.move(to: CGPoint(x: 0, y: y))
                horizontal.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            context.stroke(horizontal, with: .color(lineColor), lineWidth: 1)

            if style == .grid {
                var vertical = Path()
                var x = spacing
                while x < size.width {
                    vertical.move(to: CGPoint(x: x, y: 0))
                    vertical.addLine(to: CGPoint(x: x, y: size.height))
                    x += spacing
                }
                context.stroke(vertical, with: .color(lineColor), lineWidth: 1)
            }
        }
        .accessibilityHidden(true)
    }
}

struct WritingPencilCanvas: View {
    @Binding var drawing: PKDrawing
    let blackPaperMode: Bool
    let reloadToken: Int

    private var preferredTool: PKTool {
        PKInkingTool(.pen, color: blackPaperMode ? .white : .black, width: 2.5)
    }

    var body: some View {
        PencilDrawingCanvas(
            drawing: $drawing,
            reloadToken: reloadToken,
            backgroundColor: .clear,
            isOpaque: false,
            accessibilityLabel: "写作手写画布",
            toolAutosaveName: "PaperClip.WritingTools",
            preferredTool: preferredTool,
            preferredToolID: blackPaperMode ? "writing-white-pen" : "writing-black-pen"
        )
    }
}
