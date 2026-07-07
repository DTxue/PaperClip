import PDFKit

@MainActor
final class PDFSelectionInteractionCoordinator {
    private var selectionRect: CGRect?
    private var gestureStartPoint: CGPoint = .zero
    private var gestureStartRect: CGRect = .zero
    private var adjustment: PDFSelectionAdjustment = .creating
    private let selectionLayers = PDFSelectionLayerCoordinator()
    private var lastNotifiedSelectionRect: CGRect?

    var rect: CGRect? {
        selectionRect
    }

    func begin(at point: CGPoint, in pdfView: PDFView, notify: @escaping (CGRect?) -> Void) {
        notifySelectionRect(nil, notify: notify)
        gestureStartPoint = point
        gestureStartRect = selectionRect ?? .zero

        if let selectionRect,
           let handle = PDFSelectionGeometry.handle(at: point, in: selectionRect) {
            adjustment = .resizing(handle)
        } else if let selectionRect,
                  selectionRect.insetBy(dx: -10, dy: -10).contains(point) {
            adjustment = .moving
        } else {
            adjustment = .creating
            selectionRect = CGRect(origin: point, size: .zero)
        }
        installLayers(in: pdfView)
    }

    func update(to point: CGPoint, in bounds: CGRect) {
        let proposedRect = PDFSelectionGeometry.proposedRect(
            adjustment: adjustment,
            startPoint: gestureStartPoint,
            currentPoint: point,
            startRect: gestureStartRect
        )
        selectionRect = PDFSelectionGeometry.constrained(proposedRect, to: bounds)
        updateLayers()
    }

    func finish(at point: CGPoint, in bounds: CGRect, notify: @escaping (CGRect?) -> Void) {
        update(to: point, in: bounds)
        guard PDFSelectionGeometry.isLargeEnough(selectionRect) else {
            clear(notify: true, notifySelection: notify)
            return
        }
        guard let selectionRect else { return }
        notifySelectionRect(selectionRect, notify: notify)
    }

    func cancelIfTooSmall(notify: @escaping (CGRect?) -> Void) {
        if !PDFSelectionGeometry.isLargeEnough(selectionRect) {
            clear(notify: true, notifySelection: notify)
        }
    }

    func clear(notify: Bool = true, notifySelection: @escaping (CGRect?) -> Void) {
        selectionRect = nil
        selectionLayers.clear()
        if notify {
            notifySelectionRect(nil, notify: notifySelection)
        }
    }

    private func installLayers(in pdfView: PDFView) {
        selectionLayers.install(in: pdfView.layer)
        if let selectionRect {
            selectionLayers.update(selectionRect)
        }
    }

    private func updateLayers() {
        guard let selectionRect else { return }
        selectionLayers.update(selectionRect)
    }

    private func notifySelectionRect(_ rect: CGRect?, notify: @escaping (CGRect?) -> Void) {
        guard rect != lastNotifiedSelectionRect else { return }
        lastNotifiedSelectionRect = rect
        MainActorScheduler.async {
            notify(rect)
        }
    }
}
