import PDFKit
import PencilKit
import UIKit

extension PDFKitCanvasView.Coordinator {
        func attach(
            host: PDFDrawingHostView,
            selectionGesture: UIPanGestureRecognizer
        ) {
            self.host = host
            pdfView = host.pdfView
            loadedURL = parent.url
            self.selectionGesture = selectionGesture

            let center = NotificationCenter.default
            let notifications: [Notification.Name] = [
                .PDFViewPageChanged,
                .PDFViewScaleChanged,
                .PDFViewVisiblePagesChanged
            ]
            notifications.forEach { name in
                center.addObserver(
                    self,
                    selector: #selector(handlePDFViewChange),
                    name: name,
                    object: host.pdfView
                )
            }
            // App 回到前台（从其他 App 切回）时强制重新布局，
            // 避免 Stage Manager / Slide Over 窗口尺寸变化导致 PDF 显示不全。
            center.addObserver(
                self,
                selector: #selector(handleAppDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )

            configurePDFInteraction()
            scheduleCanvasLayout()
        }

        func updateDocumentIfNeeded(url: URL) {
            guard loadedURL != url else { return }
            guard let pdfView else { return }
            for page in Array(canvases.keys) {
                removeCanvas(for: page)
            }
            activeCanvas = nil
            pdfInteraction.resetCache()
            cropTasks.cancel()
            selectionInteraction.clear(notify: false, notifySelection: parent.onSelectionRectChanged)
            loadedURL = url
            if let document = try? PDFRenderSupport.document(at: url) {
                pdfView.document = document
            } else {
                MainActorScheduler.async { [parent] in
                    parent.onError("文件不存在、已损坏，或不是有效的 PDF。")
                }
            }
            needsPDFInteractionConfiguration = true
            needsPDFGestureTouchConfiguration = true
            pdfView.autoScales = false
            pdfView.autoScales = true
            scheduleCanvasLayout()
        }

        @objc func handlePDFViewChange() {
            scheduleCanvasLayout()
        }

        @objc func handleAppDidBecomeActive() {
            // 不直接操作 pdfView：didBecomeActive 触发时 UIKit 布局管道尚未稳定，
            // 此时 toggle autoScales 会与 PDFKit 自身的唤醒流程竞争，导致重算结果被覆盖。
            // 正确做法：通过 setNeedsLayout 将重算推迟到下一个 layoutSubviews，
            // 那里可以保证 pdfView.frame 已是最终值。
            host?.scheduleScaleReset()
            isToolPickerVisible = false
            scheduleCanvasLayout()
        }

        func tearDown() {
            NotificationCenter.default.removeObserver(self)
            cropTasks.cancel()
            selectionInteraction.clear(notify: false, notifySelection: parent.onSelectionRectChanged)
            for page in Array(canvases.keys) {
                removeCanvas(for: page)
            }
            gradeStampLayout.removeAll()
            selectionGesture = nil
            pdfView = nil
            host = nil
        }
}
