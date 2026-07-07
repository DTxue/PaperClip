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

func testCropStringParsingAndFormatting() {
    let rect = NormalizedCropString.parse("0.1,0.2,0.3,0.4")
    assert(rect != nil, "valid crop string should parse")
    assertEqual(rect!.minX, 0.1, "parsed x")
    assertEqual(rect!.minY, 0.2, "parsed y")
    assertEqual(rect!.width, 0.3, "parsed width")
    assertEqual(rect!.height, 0.4, "parsed height")
    assert(NormalizedCropString.parse("0.1,0.2,0.3") == nil, "invalid crop string should fail")
    assert(NormalizedCropString.format(rect!) == "0.1,0.2,0.3,0.4", "crop string roundtrip")
}

func testFittedFrame() {
    let frame = NormalizedCropGeometry.fittedFrame(
        imageSize: CGSize(width: 400, height: 200),
        viewSize: CGSize(width: 300, height: 300)
    )
    assertEqual(frame.width, 300, "landscape fitted width")
    assertEqual(frame.height, 150, "landscape fitted height")
    assertEqual(frame.minY, 75, "landscape centered y")
}

func testClampedNormalizedRect() {
    let rect = CGRect(x: -0.2, y: 0.98, width: 1.5, height: 0.01).clampedNormalized()
    assertEqual(rect.minX, 0, "clamped x")
    assertEqual(rect.minY, 0.95, "clamped y")
    assertEqual(rect.width, 1, "clamped width")
    assertEqual(rect.height, 0.05, "minimum height")
}

func testRectMappingAndResize() {
    let imageFrame = CGRect(x: 10, y: 20, width: 200, height: 100)
    let mapped = CGRect(x: 0.25, y: 0.2, width: 0.5, height: 0.4).rect(in: imageFrame)
    assertEqual(mapped.minX, 60, "mapped x")
    assertEqual(mapped.minY, 40, "mapped y")
    assertEqual(mapped.width, 100, "mapped width")
    assertEqual(mapped.height, 40, "mapped height")

    let resized = CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4)
        .resized(by: CGSize(width: 0.1, height: 0.05), dragState: .resizingTopLeft)
    assertEqual(resized.minX, 0.3, "resized x")
    assertEqual(resized.minY, 0.25, "resized y")
    assertEqual(resized.width, 0.3, "resized width")
    assertEqual(resized.height, 0.35, "resized height")
}

func testDragSessionAndMove() {
    let session = CropDragSession(
        state: .movingBody,
        startRect: CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4),
        startPoint: CGPoint(x: 20, y: 20)
    )
    let delta = session.normalizedDelta(
        to: CGPoint(x: 40, y: 10),
        in: CGRect(x: 0, y: 0, width: 200, height: 100)
    )
    assertEqual(delta.width, 0.1, "normalized drag dx")
    assertEqual(delta.height, -0.1, "normalized drag dy")

    let moved = session.startRect.moved(by: delta)
    assertEqual(moved.minX, 0.3, "moved x")
    assertEqual(moved.minY, 0.1, "moved y")
    assertEqual(moved.width, 0.4, "moved width")
    assertEqual(moved.height, 0.4, "moved height")

    let updated = session.updatedRect(
        to: CGPoint(x: 40, y: 10),
        in: CGRect(x: 0, y: 0, width: 200, height: 100)
    )
    assert(updated == moved, "drag session should apply its own move operation")
}

func testInitialCropRect() {
    let parsed = NormalizedCropGeometry.initialRect(from: "0.2,0.3,0.4,0.5")
    assertEqual(parsed.minX, 0.2, "initial parsed x")
    assertEqual(parsed.minY, 0.3, "initial parsed y")
    assertEqual(parsed.width, 0.4, "initial parsed width")
    assertEqual(parsed.height, 0.5, "initial parsed height")

    let fallback = NormalizedCropGeometry.initialRect(from: "bad")
    assert(fallback == NormalizedCropGeometry.defaultRect, "invalid crop should use default rect")
}

@main
enum QuestionCropGeometryTestRunner {
    static func main() {
        testCropStringParsingAndFormatting()
        testFittedFrame()
        testClampedNormalizedRect()
        testRectMappingAndResize()
        testDragSessionAndMove()
        testInitialCropRect()
        print("QuestionCropGeometryTests: 6 passed")
    }
}
