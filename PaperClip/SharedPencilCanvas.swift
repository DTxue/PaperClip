import SwiftUI
import UIKit
import PencilKit

/// 绑定 `PKDrawing` 的通用 PencilKit 画布。
/// 原生 API 评估：SwiftUI 没有等价手写轨迹控件；这里仅承载 Apple 官方
/// `PKCanvasView` 和 `PKToolPicker`，不自制画笔、颜色、粗细、橡皮或套索。
struct PencilDrawingCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var isEnabled = true
    var reloadToken = 0
    var backgroundColor: UIColor = .clear
    var isOpaque = false
    var accessibilityLabel: String
    var toolAutosaveName: String
    var preferredTool: PKTool?
    var preferredToolID: String?
    var viewport: PencilCanvasViewport?

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.configureSharedPencilCanvas(
            backgroundColor: backgroundColor,
            isOpaque: isOpaque,
            viewport: viewport
        )
        canvas.delegate = context.coordinator
        canvas.drawing = drawing
        canvas.accessibilityLabel = accessibilityLabel
        context.coordinator.lastViewport = viewport
        if let preferredTool {
            canvas.tool = preferredTool
            context.coordinator.appliedPreferredToolID = preferredToolID
        }
        context.coordinator.toolPickerController.register(canvas)
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        canvas.isUserInteractionEnabled = isEnabled
        canvas.updateSharedPencilCanvas(
            backgroundColor: backgroundColor,
            isOpaque: isOpaque,
            viewport: viewport,
            lastViewport: &context.coordinator.lastViewport
        )
        if context.coordinator.lastReloadToken != reloadToken {
            canvas.delegate = nil
            canvas.drawing = drawing
            canvas.delegate = context.coordinator
            context.coordinator.lastReloadToken = reloadToken
        }
        if let preferredTool,
           context.coordinator.appliedPreferredToolID != preferredToolID {
            canvas.tool = preferredTool
            context.coordinator.appliedPreferredToolID = preferredToolID
        }

        context.coordinator.toolPickerController.updateVisibility(
            isEnabled: isEnabled,
            for: canvas
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing, toolAutosaveName: toolAutosaveName)
    }

    static func dismantleUIView(_ canvas: PKCanvasView, coordinator: Coordinator) {
        coordinator.toolPickerController.dismantle(canvas)
        canvas.delegate = nil
    }

    @MainActor
    final class Coordinator: NSObject, PKCanvasViewDelegate {
        private var drawing: Binding<PKDrawing>
        let toolPickerController: SharedPencilToolPickerController
        var appliedPreferredToolID: String?
        var lastReloadToken = 0
        var lastViewport: PencilCanvasViewport?

        init(drawing: Binding<PKDrawing>, toolAutosaveName: String) {
            self.drawing = drawing
            self.toolPickerController = SharedPencilToolPickerController(
                toolAutosaveName: toolAutosaveName
            )
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing.wrappedValue = canvasView.drawing
        }
    }
}
