import PencilKit

private struct PencilToolPickerVisibilitySnapshot {
    let shouldShow: Bool
    let preferredCanvasID: ObjectIdentifier?
    let responderCanvasID: ObjectIdentifier?
    let responderIsFirstResponder: Bool
    let isVisible: Bool
    let pendingCanvasID: ObjectIdentifier?
}

private enum PencilToolPickerVisibilityDecision: Equatable {
    case hide
    case waitForCanvas
    case unchanged
    case pending
    case activate(canvasID: ObjectIdentifier, replacingCanvasID: ObjectIdentifier?)
}

private enum PencilToolPickerVisibilitySupport {
    static func decision(
        for snapshot: PencilToolPickerVisibilitySnapshot
    ) -> PencilToolPickerVisibilityDecision {
        guard snapshot.shouldShow else { return .hide }
        guard let preferredCanvasID = snapshot.preferredCanvasID else {
            return .waitForCanvas
        }
        if snapshot.responderCanvasID == preferredCanvasID,
           snapshot.isVisible,
           snapshot.responderIsFirstResponder {
            return .unchanged
        }
        if snapshot.pendingCanvasID == preferredCanvasID {
            return .pending
        }
        return .activate(
            canvasID: preferredCanvasID,
            replacingCanvasID: snapshot.responderCanvasID == preferredCanvasID
                ? nil
                : snapshot.responderCanvasID
        )
    }
}

@MainActor
final class SharedPencilToolPickerController {
    private let toolAutosaveName: String
    private var pendingCanvasID: ObjectIdentifier?
    private var isVisible = false
    private var requestID = UUID()
    private let maximumActivationRetries = 8
    private let activationRetryDelayNanoseconds: UInt64 = 50_000_000

    init(toolAutosaveName: String) {
        self.toolAutosaveName = toolAutosaveName
    }

    func register(_ canvas: PKCanvasView) {
        PencilToolPickerRegistry.picker(named: toolAutosaveName).addObserver(canvas)
    }

    func updateVisibility(isEnabled: Bool, for canvas: PKCanvasView) {
        let canvasID = ObjectIdentifier(canvas)
        let decision = PencilToolPickerVisibilitySupport.decision(
            for: PencilToolPickerVisibilitySnapshot(
                shouldShow: isEnabled,
                preferredCanvasID: canvasID,
                responderCanvasID: canvasID,
                responderIsFirstResponder: canvas.isFirstResponder,
                isVisible: isVisible,
                pendingCanvasID: pendingCanvasID
            )
        )

        switch decision {
        case .hide:
            hide(for: canvas)
        case .waitForCanvas, .unchanged, .pending:
            return
        case .activate:
            activate(canvas)
        }
    }

    func dismantle(_ canvas: PKCanvasView) {
        let toolPicker = PencilToolPickerRegistry.picker(named: toolAutosaveName)
        toolPicker.setVisible(false, forFirstResponder: canvas)
        toolPicker.removeObserver(canvas)
        reset()
    }

    private func hide(for canvas: PKCanvasView) {
        requestID = UUID()
        pendingCanvasID = nil
        if isVisible || canvas.isFirstResponder {
            let toolPicker = PencilToolPickerRegistry.picker(named: toolAutosaveName)
            toolPicker.setVisible(false, forFirstResponder: canvas)
            canvas.resignFirstResponder()
        }
        isVisible = false
    }

    private func activate(_ canvas: PKCanvasView) {
        let requestID = UUID()
        let canvasID = ObjectIdentifier(canvas)
        let toolPicker = PencilToolPickerRegistry.picker(named: toolAutosaveName)
        self.requestID = requestID
        pendingCanvasID = canvasID
        scheduleActivation(
            canvas,
            toolPicker: toolPicker,
            requestID: requestID,
            remainingRetries: maximumActivationRetries
        )
    }

    private func reset() {
        requestID = UUID()
        pendingCanvasID = nil
        isVisible = false
    }

    private func scheduleActivation(
        _ canvas: PKCanvasView,
        toolPicker: PKToolPicker,
        requestID: UUID,
        remainingRetries: Int
    ) {
        let canvasID = ObjectIdentifier(canvas)
        MainActorScheduler.async { [weak self, weak canvas] in
            guard let self else { return }
            guard let canvas else {
                self.clearPendingActivation(canvasID: canvasID, requestID: requestID)
                return
            }
            guard self.pendingCanvasID == canvasID,
                  self.requestID == requestID else { return }

            guard canvas.window != nil else {
                self.retryActivationIfPossible(
                    canvas,
                    toolPicker: toolPicker,
                    canvasID: canvasID,
                    requestID: requestID,
                    remainingRetries: remainingRetries
                )
                return
            }

            self.pendingCanvasID = nil
            canvas.becomeFirstResponder()
            toolPicker.setVisible(true, forFirstResponder: canvas)
            self.isVisible = true
        }
    }

    private func retryActivationIfPossible(
        _ canvas: PKCanvasView,
        toolPicker: PKToolPicker,
        canvasID: ObjectIdentifier,
        requestID: UUID,
        remainingRetries: Int
    ) {
        guard remainingRetries > 0 else {
            clearPendingActivation(canvasID: canvasID, requestID: requestID)
            return
        }

        let retryDelay = activationRetryDelayNanoseconds
        Task { @MainActor [weak self, weak canvas] in
            try? await Task.sleep(nanoseconds: retryDelay)
            guard let self, let canvas else {
                self?.clearPendingActivation(canvasID: canvasID, requestID: requestID)
                return
            }
            guard self.pendingCanvasID == canvasID,
                  self.requestID == requestID else { return }
            self.scheduleActivation(
                canvas,
                toolPicker: toolPicker,
                requestID: requestID,
                remainingRetries: remainingRetries - 1
            )
        }
    }

    private func clearPendingActivation(canvasID: ObjectIdentifier, requestID: UUID) {
        guard pendingCanvasID == canvasID,
              self.requestID == requestID else { return }
        pendingCanvasID = nil
        isVisible = false
    }
}
