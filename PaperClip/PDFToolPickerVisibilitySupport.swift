import Foundation

struct PencilToolPickerVisibilitySnapshot {
    let shouldShow: Bool
    let preferredCanvasID: ObjectIdentifier?
    let responderCanvasID: ObjectIdentifier?
    let responderIsFirstResponder: Bool
    let isVisible: Bool
    let pendingCanvasID: ObjectIdentifier?
}

enum PencilToolPickerVisibilityDecision: Equatable {
    case hide
    case waitForCanvas
    case unchanged
    case pending
    case activate(canvasID: ObjectIdentifier, replacingCanvasID: ObjectIdentifier?)
}

enum PencilToolPickerVisibilitySupport {
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

typealias PDFToolPickerVisibilitySnapshot = PencilToolPickerVisibilitySnapshot
typealias PDFToolPickerVisibilityDecision = PencilToolPickerVisibilityDecision
typealias PDFToolPickerVisibilitySupport = PencilToolPickerVisibilitySupport
