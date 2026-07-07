import PDFKit
import PencilKit
import UIKit

extension PDFKitCanvasView.Coordinator {
    func registerWithToolPicker(_ canvas: PKCanvasView) {
        let canvasID = ObjectIdentifier(canvas)
        guard toolPickerCanvasIDs.insert(canvasID).inserted else { return }
        toolPicker.addObserver(canvas)
    }

    func updateToolPickerVisibility() {
        guard pdfView != nil else { return }

        let canvas = preferredCanvas()
        let decision = PDFToolPickerVisibilitySupport.decision(
            for: PDFToolPickerVisibilitySnapshot(
                shouldShow: shouldShowToolPicker,
                preferredCanvasID: canvas.map(ObjectIdentifier.init),
                responderCanvasID: toolPickerResponder.map(ObjectIdentifier.init),
                responderIsFirstResponder: toolPickerResponder?.isFirstResponder ?? false,
                isVisible: isToolPickerVisible,
                pendingCanvasID: pendingToolPickerCanvasID
            )
        )

        switch decision {
        case .hide:
            toolPickerActivationRequestID = UUID()
            if let responder = toolPickerResponder {
                toolPicker.setVisible(false, forFirstResponder: responder)
                responder.resignFirstResponder()
            }
            toolPickerResponder = nil
            isToolPickerVisible = false
            pendingToolPickerCanvasID = nil
        case .waitForCanvas:
            scheduleCanvasLayout()
        case .unchanged, .pending:
            break
        case let .activate(canvasID, replacingCanvasID):
            if let replacingCanvasID,
               let previousResponder = toolPickerResponder,
               ObjectIdentifier(previousResponder) == replacingCanvasID {
                toolPicker.setVisible(false, forFirstResponder: previousResponder)
                previousResponder.resignFirstResponder()
                isToolPickerVisible = false
            }
            guard let canvas,
                  ObjectIdentifier(canvas) == canvasID
            else {
                scheduleCanvasLayout()
                return
            }
            registerWithToolPicker(canvas)
            toolPickerResponder = canvas
            pendingToolPickerCanvasID = canvasID
            let requestID = UUID()
            toolPickerActivationRequestID = requestID
            scheduleToolPickerActivation(
                canvas,
                requestID: requestID,
                remainingRetries: maximumToolPickerActivationRetries
            )
        }
    }

    var shouldShowToolPicker: Bool {
        parent.isWritingEnabled
            && !parent.isSelectionMode
            && parent.isDrawingVisible
    }

    func preferredCanvas() -> PKCanvasView? {
        if let currentPage = pdfView?.currentPage,
           let canvas = canvases[currentPage] {
            return canvas
        }
        for page in pdfView?.visiblePages ?? [] {
            if let canvas = canvases[page] {
                return canvas
            }
        }
        if let activeCanvas {
            return activeCanvas
        }
        return canvases.values.first
    }

    private func scheduleToolPickerActivation(
        _ canvas: PKCanvasView,
        requestID: UUID,
        remainingRetries: Int
    ) {
        let canvasID = ObjectIdentifier(canvas)
        MainActorScheduler.async { [weak self, weak canvas] in
            guard let self else { return }
            guard let canvas else {
                self.clearPendingToolPickerActivation(canvasID: canvasID, requestID: requestID)
                return
            }
            guard self.pendingToolPickerCanvasID == canvasID,
                  self.toolPickerActivationRequestID == requestID else { return }

            guard self.shouldShowToolPicker else {
                self.clearPendingToolPickerActivation(canvasID: canvasID, requestID: requestID)
                return
            }
            guard canvas.window != nil else {
                self.retryToolPickerActivationIfPossible(
                    canvas,
                    canvasID: canvasID,
                    requestID: requestID,
                    remainingRetries: remainingRetries
                )
                return
            }

            self.pendingToolPickerCanvasID = nil
            canvas.becomeFirstResponder()
            self.toolPicker.setVisible(true, forFirstResponder: canvas)
            self.isToolPickerVisible = true
        }
    }

    private func retryToolPickerActivationIfPossible(
        _ canvas: PKCanvasView,
        canvasID: ObjectIdentifier,
        requestID: UUID,
        remainingRetries: Int
    ) {
        guard remainingRetries > 0 else {
            clearPendingToolPickerActivation(canvasID: canvasID, requestID: requestID)
            scheduleCanvasLayout()
            return
        }

        let retryDelay = toolPickerActivationRetryDelayNanoseconds
        Task { @MainActor [weak self, weak canvas] in
            try? await Task.sleep(nanoseconds: retryDelay)
            guard let self, let canvas else {
                self?.clearPendingToolPickerActivation(canvasID: canvasID, requestID: requestID)
                return
            }
            guard self.pendingToolPickerCanvasID == canvasID,
                  self.toolPickerActivationRequestID == requestID else { return }
            self.scheduleToolPickerActivation(
                canvas,
                requestID: requestID,
                remainingRetries: remainingRetries - 1
            )
        }
    }

    private func clearPendingToolPickerActivation(canvasID: ObjectIdentifier, requestID: UUID) {
        guard pendingToolPickerCanvasID == canvasID,
              toolPickerActivationRequestID == requestID else { return }
        pendingToolPickerCanvasID = nil
        isToolPickerVisible = false
    }
}
