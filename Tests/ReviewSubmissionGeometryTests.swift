import CoreGraphics
import Foundation

private func expect(
    _ condition: @autoclosure () -> Bool,
    _ message: String,
    file: StaticString = #file,
    line: UInt = #line
) {
    guard condition() else {
        fatalError(message, file: file, line: line)
    }
}

@main
enum ReviewSubmissionGeometryTests {
    static func main() {
        testUsesMediaBoundsWhenCropBoxIsEmpty()
        testConvertsCropBoxToDrawingBounds()
        testStandardizesInputRects()
        testRejectsInvalidPages()

        print("ReviewSubmissionGeometryTests: 4 passed")
    }

    private static func testUsesMediaBoundsWhenCropBoxIsEmpty() {
        let geometry = ReviewSubmissionGeometry.pageGeometry(
            mediaBounds: CGRect(x: 0, y: 0, width: 600, height: 800),
            cropBounds: .zero
        )

        expect(geometry != nil, "valid media bounds should produce geometry")
        expect(geometry!.displayBounds == CGRect(x: 0, y: 0, width: 600, height: 800), "display should fall back to media bounds")
        expect(geometry!.drawingBounds == CGRect(x: 0, y: 0, width: 600, height: 800), "full media drawing should start at origin")
    }

    private static func testConvertsCropBoxToDrawingBounds() {
        let geometry = ReviewSubmissionGeometry.pageGeometry(
            mediaBounds: CGRect(x: 0, y: 0, width: 600, height: 800),
            cropBounds: CGRect(x: 50, y: 100, width: 300, height: 400)
        )

        expect(geometry != nil, "valid crop bounds should produce geometry")
        expect(geometry!.displayBounds == CGRect(x: 50, y: 100, width: 300, height: 400), "display should use crop bounds")
        expect(
            geometry!.drawingBounds == CGRect(x: 50, y: 300, width: 300, height: 400),
            "drawing bounds should convert PDF lower-left crop coordinates to PencilKit upper-left coordinates"
        )
    }

    private static func testStandardizesInputRects() {
        let geometry = ReviewSubmissionGeometry.pageGeometry(
            mediaBounds: CGRect(x: 0, y: 800, width: 600, height: -800),
            cropBounds: CGRect(x: 350, y: 500, width: -300, height: -400)
        )

        expect(geometry != nil, "negative-size rects should be standardized")
        expect(geometry!.displayBounds == CGRect(x: 50, y: 100, width: 300, height: 400), "crop should be standardized")
        expect(geometry!.drawingBounds == CGRect(x: 50, y: 300, width: 300, height: 400), "standardized crop should convert consistently")
    }

    private static func testRejectsInvalidPages() {
        expect(
            ReviewSubmissionGeometry.pageGeometry(mediaBounds: .zero, cropBounds: .zero) == nil,
            "empty media bounds should be rejected"
        )
        expect(
            ReviewSubmissionGeometry.pageGeometry(
                mediaBounds: CGRect(x: 0, y: 0, width: 600, height: 0),
                cropBounds: CGRect(x: 0, y: 0, width: 100, height: 100)
            ) == nil,
            "invalid media bounds should be rejected even when crop bounds are present"
        )
    }
}
