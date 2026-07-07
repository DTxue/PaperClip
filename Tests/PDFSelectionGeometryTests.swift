import CoreGraphics
import Foundation

@discardableResult
func assert(_ condition: @autoclosure () -> Bool, _ message: String) -> Bool {
    if !condition() {
        print("FAIL: \(message)")
        exit(1)
    }
    return true
}

func assertEqual(_ lhs: CGFloat, _ rhs: CGFloat, accuracy: CGFloat = 0.0001, _ message: String) {
    assert(abs(lhs - rhs) <= accuracy, message)
}

func testHandlePoints() {
    let rect = CGRect(x: 10, y: 20, width: 100, height: 60)
    assert(PDFSelectionGeometry.point(for: .topLeft, in: rect) == CGPoint(x: 10, y: 20), "top-left handle")
    assert(PDFSelectionGeometry.point(for: .right, in: rect) == CGPoint(x: 110, y: 50), "right handle")
    assert(PDFSelectionGeometry.point(for: .bottom, in: rect) == CGPoint(x: 60, y: 80), "bottom handle")
}

func testHandleHitTesting() {
    let rect = CGRect(x: 10, y: 20, width: 100, height: 60)
    assert(PDFSelectionGeometry.handle(at: CGPoint(x: 12, y: 22), in: rect) == .topLeft, "near top-left handle")
    assert(PDFSelectionGeometry.handle(at: CGPoint(x: 250, y: 250), in: rect) == nil, "far point should miss")
}

func testResizeAndNormalize() {
    let rect = CGRect(x: 50, y: 60, width: 80, height: 40)
    let resized = PDFSelectionGeometry.resizedRect(
        rect,
        using: .topLeft,
        translation: CGPoint(x: 20, y: -10)
    )
    assertEqual(resized.minX, 70, "resized x")
    assertEqual(resized.minY, 50, "resized y")
    assertEqual(resized.width, 60, "resized width")
    assertEqual(resized.height, 50, "resized height")

    let normalized = PDFSelectionGeometry.normalizedRect(
        from: CGPoint(x: 100, y: 80),
        to: CGPoint(x: 40, y: 20)
    )
    assertEqual(normalized.minX, 40, "normalized x")
    assertEqual(normalized.minY, 20, "normalized y")
    assertEqual(normalized.width, 60, "normalized width")
    assertEqual(normalized.height, 60, "normalized height")
}

func testProposedRectForSelectionAdjustments() {
    let start = CGPoint(x: 10, y: 20)
    let current = CGPoint(x: 50, y: 70)
    let startRect = CGRect(x: 30, y: 40, width: 80, height: 60)

    let creating = PDFSelectionGeometry.proposedRect(
        adjustment: .creating,
        startPoint: start,
        currentPoint: current,
        startRect: startRect
    )
    assertEqual(creating.minX, 10, "creating x")
    assertEqual(creating.minY, 20, "creating y")
    assertEqual(creating.width, 40, "creating width")
    assertEqual(creating.height, 50, "creating height")

    let moving = PDFSelectionGeometry.proposedRect(
        adjustment: .moving,
        startPoint: start,
        currentPoint: current,
        startRect: startRect
    )
    assertEqual(moving.minX, 70, "moving x")
    assertEqual(moving.minY, 90, "moving y")

    let resizing = PDFSelectionGeometry.proposedRect(
        adjustment: .resizing(.bottomRight),
        startPoint: start,
        currentPoint: current,
        startRect: startRect
    )
    assertEqual(resizing.width, 120, "resizing width")
    assertEqual(resizing.height, 110, "resizing height")
}

func testMinimumSelectionSize() {
    assert(!PDFSelectionGeometry.isLargeEnough(nil), "nil selection should be invalid")
    assert(
        !PDFSelectionGeometry.isLargeEnough(CGRect(x: 0, y: 0, width: 31.9, height: 32)),
        "selection narrower than minimum should be invalid"
    )
    assert(
        PDFSelectionGeometry.isLargeEnough(CGRect(x: 0, y: 0, width: 32, height: 32)),
        "minimum-sized selection should be valid"
    )
}

func testConstrainedRect() {
    let bounds = CGRect(x: 0, y: 0, width: 200, height: 120)
    let constrained = PDFSelectionGeometry.constrained(
        CGRect(x: 180, y: -20, width: 60, height: 50),
        to: bounds
    )
    assertEqual(constrained.minX, 140, "constrained x")
    assertEqual(constrained.minY, 0, "constrained y")
    assertEqual(constrained.width, 60, "constrained width")
    assertEqual(constrained.height, 50, "constrained height")

    let oversized = PDFSelectionGeometry.constrained(
        CGRect(x: -10, y: -10, width: 300, height: 200),
        to: bounds
    )
    assertEqual(oversized.minX, 0, "oversized x")
    assertEqual(oversized.minY, 0, "oversized y")
    assertEqual(oversized.width, 200, "oversized width")
    assertEqual(oversized.height, 120, "oversized height")
}

@main
enum PDFSelectionGeometryTestRunner {
    static func main() {
        testHandlePoints()
        testHandleHitTesting()
        testResizeAndNormalize()
        testProposedRectForSelectionAdjustments()
        testMinimumSelectionSize()
        testConstrainedRect()
        print("PDFSelectionGeometryTests: 6 passed")
    }
}
