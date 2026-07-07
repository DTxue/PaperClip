import Foundation
import CoreGraphics

extension PDFKitCanvasView.Coordinator {
    func reportCanvasSizesIfNeeded(_ sizes: [Int: CGSize]) {
        guard CanvasSizeReportSupport.hasMeaningfulChange(
            from: lastReportedCanvasSizes,
            to: sizes
        ) else { return }

        lastReportedCanvasSizes = sizes
        let onCanvasSizesChanged = parent.onCanvasSizesChanged
        MainActorScheduler.async {
            onCanvasSizesChanged?(sizes)
        }
    }
}
