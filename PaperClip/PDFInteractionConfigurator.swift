import PDFKit
import PencilKit
import UIKit

@MainActor
final class PDFInteractionConfigurator {
    private weak var cachedPDFScrollView: UIScrollView?

    private static let nonPencilTouchTypes = [
        NSNumber(value: UITouch.TouchType.direct.rawValue),
        NSNumber(value: UITouch.TouchType.indirect.rawValue),
        NSNumber(value: UITouch.TouchType.indirectPointer.rawValue)
    ]

    func resetCache() {
        cachedPDFScrollView = nil
    }

    func configure(
        pdfView: PDFView,
        selectionGesture: UIGestureRecognizer?,
        isSelectionMode: Bool,
        configureGestureTouchTypes: Bool
    ) {
        if configureGestureTouchTypes {
            configurePDFGestures(
                in: pdfView,
                selectionGesture: selectionGesture,
                allowedTouchTypes: Self.nonPencilTouchTypes
            )
        }

        if let scrollView = currentPDFScrollView(in: pdfView) {
            scrollView.isScrollEnabled = !isSelectionMode
            scrollView.delaysContentTouches = false
            scrollView.canCancelContentTouches = true
            scrollView.panGestureRecognizer.minimumNumberOfTouches = 1
        }
    }

    private func configurePDFGestures(
        in view: UIView,
        selectionGesture: UIGestureRecognizer?,
        allowedTouchTypes: [NSNumber]
    ) {
        guard !(view is PKCanvasView) else { return }

        view.gestureRecognizers?.forEach { gesture in
            if gesture !== selectionGesture {
                let currentTouchTypes = gesture.allowedTouchTypes
                if currentTouchTypes != allowedTouchTypes {
                    gesture.allowedTouchTypes = allowedTouchTypes
                }
            }
        }
        view.subviews.forEach {
            configurePDFGestures(
                in: $0,
                selectionGesture: selectionGesture,
                allowedTouchTypes: allowedTouchTypes
            )
        }
    }

    private func pdfScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView,
           !(scrollView is PKCanvasView) {
            return scrollView
        }
        for subview in view.subviews {
            if let scrollView = pdfScrollView(in: subview) {
                return scrollView
            }
        }
        return nil
    }

    private func currentPDFScrollView(in view: UIView) -> UIScrollView? {
        if let cachedPDFScrollView, cachedPDFScrollView.superview != nil {
            return cachedPDFScrollView
        }
        let scrollView = pdfScrollView(in: view)
        cachedPDFScrollView = scrollView
        return scrollView
    }
}
