import PDFKit
import PencilKit
import UIKit

extension PDFKitCanvasView.Coordinator {
        func updateCanvasesIfNeeded() {
            let configuration = PDFCanvasConfiguration(
                isWritingEnabled: parent.isWritingEnabled,
                isDrawingVisible: parent.isDrawingVisible
            )
            guard configuration != lastCanvasConfiguration
                || parent.writablePageIndices != lastWritablePageIndices
            else { return }
            lastCanvasConfiguration = configuration
            lastWritablePageIndices = parent.writablePageIndices
            canvases.values.forEach(configure)
        }

        func removeCanvas(for page: PDFPage) {
            guard let canvas = canvases.removeValue(forKey: page) else { return }
            let canvasID = ObjectIdentifier(canvas)

            if toolPickerResponder === canvas {
                toolPicker.setVisible(false, forFirstResponder: canvas)
                canvas.resignFirstResponder()
                toolPickerResponder = nil
                isToolPickerVisible = false
            }
            if pendingToolPickerCanvasID == canvasID {
                pendingToolPickerCanvasID = nil
            }
            if activeCanvas === canvas {
                activeCanvas = nil
            }

            canvas.delegate = nil
            toolPicker.removeObserver(canvas)
            toolPickerCanvasIDs.remove(canvasID)
            pageIndexByCanvas.removeValue(forKey: canvasID)
            canvas.removeFromSuperview()
        }

        func configure(_ canvas: PKCanvasView) {
            let pageIndex = pageIndexByCanvas[ObjectIdentifier(canvas)]
            let canWritePage = pageIndex.map { pageIndex in
                parent.writablePageIndices?.contains(pageIndex) ?? true
            } ?? false
            PDFCanvasFactory.configure(
                canvas,
                configuration: PDFCanvasConfiguration(
                    isWritingEnabled: parent.isWritingEnabled && canWritePage,
                    isDrawingVisible: parent.isDrawingVisible
                )
            )
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            activeCanvas = canvasView
            persist(canvasView)
        }

        func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
            activeCanvas = canvasView
            toolPickerResponder = canvasView
        }

        func persist(_ canvas: PKCanvasView) {
            guard let index = pageIndexByCanvas[ObjectIdentifier(canvas)] else { return }
            parent.onDrawingChanged(index, canvas.drawing)
        }

        func clearAllDrawings() {
            canvases.values.forEach { canvas in
                PDFCanvasFactory.setDrawingSilently(PKDrawing(), in: canvas, delegate: self)
            }
            activeCanvas = nil
        }

        /// 销毁全部 canvas 并从 parent.drawings 重新加载，切换做题会话时调用。
        func reloadAllCanvases() {
            for page in Array(canvases.keys) {
                removeCanvas(for: page)
            }
            activeCanvas = nil
            scheduleCanvasLayout()
        }


}
