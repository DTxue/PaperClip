import Foundation

final class CanvasToken {}

@discardableResult
func expect(_ condition: @autoclosure () -> Bool, _ message: String) -> Bool {
    if !condition() {
        print("FAIL: \(message)")
        exit(1)
    }
    return true
}

func testHidesWhenDrawingShouldNotUseToolPicker() {
    let canvas = CanvasToken()
    let canvasID = ObjectIdentifier(canvas)

    let decision = PDFToolPickerVisibilitySupport.decision(
        for: PDFToolPickerVisibilitySnapshot(
            shouldShow: false,
            preferredCanvasID: canvasID,
            responderCanvasID: canvasID,
            responderIsFirstResponder: true,
            isVisible: true,
            pendingCanvasID: nil
        )
    )

    expect(decision == .hide, "disabled writing should hide the tool picker")
}

func testWaitsWhenNoCanvasIsReady() {
    let decision = PDFToolPickerVisibilitySupport.decision(
        for: PDFToolPickerVisibilitySnapshot(
            shouldShow: true,
            preferredCanvasID: nil,
            responderCanvasID: nil,
            responderIsFirstResponder: false,
            isVisible: false,
            pendingCanvasID: nil
        )
    )

    expect(decision == .waitForCanvas, "missing preferred canvas should request layout")
}

func testSkipsWhenPreferredResponderIsAlreadyVisible() {
    let canvas = CanvasToken()
    let canvasID = ObjectIdentifier(canvas)

    let decision = PDFToolPickerVisibilitySupport.decision(
        for: PDFToolPickerVisibilitySnapshot(
            shouldShow: true,
            preferredCanvasID: canvasID,
            responderCanvasID: canvasID,
            responderIsFirstResponder: true,
            isVisible: true,
            pendingCanvasID: nil
        )
    )

    expect(decision == .unchanged, "visible preferred responder should not be reactivated")
}

func testSkipsDuplicatePendingActivation() {
    let canvas = CanvasToken()
    let canvasID = ObjectIdentifier(canvas)

    let decision = PDFToolPickerVisibilitySupport.decision(
        for: PDFToolPickerVisibilitySnapshot(
            shouldShow: true,
            preferredCanvasID: canvasID,
            responderCanvasID: canvasID,
            responderIsFirstResponder: false,
            isVisible: false,
            pendingCanvasID: canvasID
        )
    )

    expect(decision == .pending, "pending preferred canvas should not enqueue another activation")
}

func testActivatesPreferredCanvasAndReplacesPreviousResponder() {
    let previous = CanvasToken()
    let preferred = CanvasToken()
    let previousID = ObjectIdentifier(previous)
    let preferredID = ObjectIdentifier(preferred)

    let decision = PDFToolPickerVisibilitySupport.decision(
        for: PDFToolPickerVisibilitySnapshot(
            shouldShow: true,
            preferredCanvasID: preferredID,
            responderCanvasID: previousID,
            responderIsFirstResponder: true,
            isVisible: true,
            pendingCanvasID: nil
        )
    )

    expect(
        decision == .activate(canvasID: preferredID, replacingCanvasID: previousID),
        "preferred canvas should replace the previous responder"
    )
}

func testReactivatesSameCanvasWithoutReplacement() {
    let canvas = CanvasToken()
    let canvasID = ObjectIdentifier(canvas)

    let decision = PencilToolPickerVisibilitySupport.decision(
        for: PencilToolPickerVisibilitySnapshot(
            shouldShow: true,
            preferredCanvasID: canvasID,
            responderCanvasID: canvasID,
            responderIsFirstResponder: false,
            isVisible: false,
            pendingCanvasID: nil
        )
    )

    expect(
        decision == .activate(canvasID: canvasID, replacingCanvasID: nil),
        "same canvas should reactivate without replacing itself"
    )
}

@main
enum PDFToolPickerVisibilitySupportTestRunner {
    static func main() {
        testHidesWhenDrawingShouldNotUseToolPicker()
        testWaitsWhenNoCanvasIsReady()
        testSkipsWhenPreferredResponderIsAlreadyVisible()
        testSkipsDuplicatePendingActivation()
        testActivatesPreferredCanvasAndReplacesPreviousResponder()
        testReactivatesSameCanvasWithoutReplacement()
        print("PDFToolPickerVisibilitySupportTests: 6 passed")
    }
}
