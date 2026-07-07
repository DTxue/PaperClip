import PDFKit
import PencilKit
import UIKit

extension PDFKitCanvasView.Coordinator {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        false
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        parent.isSelectionMode
    }

    @objc func handleSelection(_ gesture: UIPanGestureRecognizer) {
        guard let pdfView else { return }
        let point = gesture.location(in: pdfView)
        let notifySelection = parent.onSelectionRectChanged

        switch gesture.state {
        case .began:
            selectionInteraction.begin(at: point, in: pdfView, notify: notifySelection)
        case .changed:
            selectionInteraction.update(to: point, in: pdfView.bounds)
        case .ended:
            selectionInteraction.finish(at: point, in: pdfView.bounds, notify: notifySelection)
        default:
            selectionInteraction.cancelIfTooSmall(notify: notifySelection)
        }
    }

    func confirmSelection(action: PDFSelectionAction) {
        guard let pdfView,
              let viewRect = selectionInteraction.rect,
              let page = pdfView.page(
                for: CGPoint(x: viewRect.midX, y: viewRect.midY),
                nearest: true
              ),
              let document = pdfView.document
        else { return }

        let pageRect = pdfView.convert(viewRect, to: page)
        let pageBounds = page.bounds(for: .mediaBox)
        let boundedRect = PDFCropGeometry.boundedCrop(pageRect, in: pageBounds)
        let pageIndex = document.index(for: page)
        guard let boundedRect,
              pageIndex >= 0
        else { return }

        selectionInteraction.clear(notifySelection: parent.onSelectionRectChanged)
        cropTasks.start(
            pdfURL: parent.url,
            pageIndex: pageIndex,
            cropRect: boundedRect,
            action: action,
            onCrop: parent.onCrop
        )
    }

    func clearSelection(notify: Bool = true) {
        selectionInteraction.clear(
            notify: notify,
            notifySelection: parent.onSelectionRectChanged
        )
    }
}
