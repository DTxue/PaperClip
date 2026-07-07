import PencilKit
import SwiftUI

/// 答题用 PKCanvasView：Apple Pencil 绘图，手指滚动父 ScrollView。
/// 使用共享 PencilDrawingCanvas 承载 Apple 官方 PKCanvasView 和 PKToolPicker。
struct AnswerCanvas: View {
    @Binding var drawing: PKDrawing
    var reloadToken = 0

    var body: some View {
        PencilDrawingCanvas(
            drawing: $drawing,
            reloadToken: reloadToken,
            backgroundColor: .systemBackground,
            isOpaque: true,
            accessibilityLabel: "答题手写画布",
            toolAutosaveName: "PaperClip.PaperAnswerTools"
        )
    }
}
