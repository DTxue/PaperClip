import CoreGraphics
import Foundation

@discardableResult
func expect(_ condition: @autoclosure () -> Bool, _ message: String) -> Bool {
    if !condition() {
        print("FAIL: \(message)")
        exit(1)
    }
    return true
}

func expectEqual(_ lhs: CGFloat, _ rhs: CGFloat, accuracy: CGFloat = 0.0001, _ message: String) {
    expect(abs(lhs - rhs) <= accuracy, message)
}

func testInkCropSpecAppliesPaddingAndScale() {
    let spec = HandwritingRenderGeometry.inkCropSpec(
        inkBounds: CGRect(x: 10, y: 20, width: 100.25, height: 40.25),
        padding: 20,
        scale: 2
    )

    expect(spec != nil, "valid ink bounds should produce a render spec")
    expectEqual(spec!.sourceRect.minX, -10, "source rect x should include padding")
    expectEqual(spec!.sourceRect.minY, 0, "source rect y should include padding")
    expectEqual(spec!.sourceRect.width, 140.25, "source rect width should include padding")
    expectEqual(spec!.sourceRect.height, 80.25, "source rect height should include padding")
    expect(spec!.outputSize == CGSize(width: 281, height: 161), "output size should round scaled pixels")
    expectEqual(spec!.drawingScale, 2, "drawing scale should be preserved")
}

func testInkCropSpecRejectsInvalidInput() {
    expect(
        HandwritingRenderGeometry.inkCropSpec(inkBounds: .zero) == nil,
        "empty ink bounds should not render"
    )
    expect(
        HandwritingRenderGeometry.inkCropSpec(
            inkBounds: CGRect(x: 0, y: 0, width: 20, height: 20),
            padding: -1
        ) == nil,
        "negative padding should be rejected"
    )
    expect(
        HandwritingRenderGeometry.inkCropSpec(
            inkBounds: CGRect(x: 0, y: 0, width: 20, height: 20),
            scale: 0
        ) == nil,
        "invalid scale should be rejected"
    )
}

func testFullCanvasSpecUsesCanvasSizeAndScale() {
    let spec = HandwritingRenderGeometry.fullCanvasSpec(
        canvasSize: CGSize(width: 820, height: 1500),
        scale: 2
    )

    expect(spec != nil, "valid canvas should produce a render spec")
    expect(spec!.sourceRect == CGRect(x: 0, y: 0, width: 820, height: 1500), "source rect should match canvas")
    expect(spec!.outputSize == CGSize(width: 820, height: 1500), "logical output size should match canvas")
    expectEqual(spec!.drawingScale, 2, "drawing scale should be preserved")
}

@main
enum HandwritingRenderGeometryTestRunner {
    static func main() {
        testInkCropSpecAppliesPaddingAndScale()
        testInkCropSpecRejectsInvalidInput()
        testFullCanvasSpecUsesCanvasSizeAndScale()
        print("HandwritingRenderGeometryTests: 3 passed")
    }
}
