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

func testBoundedCropIntersectsPageBounds() {
    let pageBounds = CGRect(x: 10, y: 20, width: 300, height: 400)
    let crop = PDFCropGeometry.boundedCrop(
        CGRect(x: 0, y: 30, width: 120, height: 80),
        in: pageBounds
    )

    expect(crop != nil, "overlapping crop should be valid")
    expectEqual(crop!.minX, 10, "bounded crop x")
    expectEqual(crop!.minY, 30, "bounded crop y")
    expectEqual(crop!.width, 110, "bounded crop width")
    expectEqual(crop!.height, 80, "bounded crop height")
}

func testBoundedCropStandardizesInput() {
    let crop = PDFCropGeometry.boundedCrop(
        CGRect(x: 120, y: 140, width: -80, height: -60),
        in: CGRect(x: 0, y: 0, width: 200, height: 200)
    )

    expect(crop != nil, "negative-size crop should be standardized")
    expectEqual(crop!.minX, 40, "standardized x")
    expectEqual(crop!.minY, 80, "standardized y")
    expectEqual(crop!.width, 80, "standardized width")
    expectEqual(crop!.height, 60, "standardized height")
}

func testRejectsInvalidOrTooSmallCrop() {
    let pageBounds = CGRect(x: 0, y: 0, width: 200, height: 200)

    expect(
        PDFCropGeometry.boundedCrop(CGRect(x: 50, y: 50, width: 8, height: 20), in: pageBounds) == nil,
        "minimum crop width should be exclusive"
    )
    expect(
        PDFCropGeometry.boundedCrop(CGRect(x: 250, y: 250, width: 20, height: 20), in: pageBounds) == nil,
        "non-overlapping crop should be rejected"
    )
    expect(
        PDFCropGeometry.boundedCrop(CGRect(x: 0, y: 0, width: 20, height: 20), in: .zero) == nil,
        "empty page bounds should be rejected"
    )
}

func testOutputSizeUsesRenderScale() {
    let size = PDFCropGeometry.outputSize(
        for: CGRect(x: 0, y: 0, width: 42, height: 24),
        scale: 3
    )

    expect(size == CGSize(width: 126, height: 72), "output size should multiply by render scale")
    expect(PDFCropGeometry.outputSize(for: .zero) == nil, "empty crop output should be rejected")
    expect(
        PDFCropGeometry.outputSize(for: CGRect(x: 0, y: 0, width: 20, height: 20), scale: 0) == nil,
        "invalid render scale should be rejected"
    )
}

func testOutputSizeMatchesSharedPageRenderScale() {
    let crop = CGRect(x: 24, y: 36, width: 90, height: 120)
    let outputSize = PDFCropGeometry.outputSize(for: crop)
    expect(outputSize != nil, "crop output size should be valid")

    let scale = PDFPageRenderGeometry.pageScale(
        bounds: crop,
        destination: CGRect(origin: .zero, size: outputSize!)
    )

    expect(scale == PDFPageRenderScale(
        x: PDFCropGeometry.defaultRenderScale,
        y: PDFCropGeometry.defaultRenderScale
    ), "shared page renderer scale should match crop render scale")
}

@main
enum PDFCropGeometryTestRunner {
    static func main() {
        testBoundedCropIntersectsPageBounds()
        testBoundedCropStandardizesInput()
        testRejectsInvalidOrTooSmallCrop()
        testOutputSizeUsesRenderScale()
        testOutputSizeMatchesSharedPageRenderScale()
        print("PDFCropGeometryTests: 5 passed")
    }
}
