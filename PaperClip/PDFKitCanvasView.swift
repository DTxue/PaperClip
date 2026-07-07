import SwiftUI
import PDFKit
import PencilKit

/// PDFKit 阅读器与 PencilKit 答题图层的桥接 view。
/// 原生 API 评估：SwiftUI 没有等价的 PDFKit 阅读 + 每页独立 PKCanvasView 覆盖层；
/// 这里保留 Apple 官方 `PDFView`、`PKCanvasView`、`PKToolPicker`，自定义部分仅负责
/// 按 PDF 页面坐标挂载答题图层、框选裁剪和可见页布局，不重写系统画笔、缩放或分享能力。
struct PDFKitCanvasView: UIViewRepresentable {
    let url: URL
    let drawings: [Int: Data]
    let gradeStamps: [PDFGradeStamp]
    let isWritingEnabled: Bool
    let isDrawingVisible: Bool
    let isSelectionMode: Bool
    let selectionAction: PDFSelectionAction?
    let selectionActionToken: Int
    let cancelSelectionToken: Int
    let undoToken: Int
    let redoToken: Int
    let clearAnswersToken: Int
    /// 变化时销毁所有 canvas 并从 drawings 重新加载，用于切换做题会话。
    let reloadDrawingsToken: Int
    let onDrawingChanged: (Int, PKDrawing) -> Void
    let onSelectionRectChanged: (CGRect?) -> Void
    let onCrop: (UIImage, Double, Double, PDFSelectionAction) -> Void
    let onError: (String) -> Void
    /// 每页画布的精确尺寸（页面索引 → canvas.frame.size），布局完成后回调，供导出合成使用。
    var onCanvasSizesChanged: (([Int: CGSize]) -> Void)? = nil

    @MainActor
    final class Coordinator: NSObject,
        PKCanvasViewDelegate,
        UIGestureRecognizerDelegate
    {
        var parent: PDFKitCanvasView
        weak var host: PDFDrawingHostView?
        weak var pdfView: PDFView?
        weak var selectionGesture: UIPanGestureRecognizer?
        weak var activeCanvas: PKCanvasView?
        var loadedURL: URL?

        var canvases: [PDFPage: PKCanvasView] = [:]
        var pageIndexByCanvas: [ObjectIdentifier: Int] = [:]
        let gradeStampLayout = PDFGradeStampLayoutCoordinator()
        let pdfInteraction = PDFInteractionConfigurator()
        let toolPicker = PencilToolPickerRegistry.picker(named: "PaperClip.PDFTools")
        var toolPickerCanvasIDs: Set<ObjectIdentifier> = []
        weak var toolPickerResponder: PKCanvasView?
        var updateState = PDFCanvasUpdateState()

        var isCanvasLayoutScheduled = false
        let selectionInteraction = PDFSelectionInteractionCoordinator()
        var needsPDFInteractionConfiguration = true
        var needsPDFGestureTouchConfiguration = true
        var lastConfiguredSelectionMode: Bool?
        var lastReportedCanvasSizes: [Int: CGSize] = [:]
        var lastCanvasConfiguration: PDFCanvasConfiguration?
        var isToolPickerVisible = false
        var pendingToolPickerCanvasID: ObjectIdentifier?
        var toolPickerActivationRequestID = UUID()
        let maximumToolPickerActivationRetries = 8
        let toolPickerActivationRetryDelayNanoseconds: UInt64 = 50_000_000
        let cropTasks = PDFCropTaskCoordinator()
        init(parent: PDFKitCanvasView) {
            self.parent = parent
            super.init()
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }


    }
}
