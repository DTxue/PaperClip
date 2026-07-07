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
enum PDFPageRenderGeometryTests {
    static func main() {
        testPageScaleMapsBoundsToDestination()
        testPageScaleIgnoresOrigins()
        testPageScaleRejectsInvalidRects()

        print("PDFPageRenderGeometryTests: 3 passed")
    }

    private static func testPageScaleMapsBoundsToDestination() {
        let scale = PDFPageRenderGeometry.pageScale(
            bounds: CGRect(x: 0, y: 0, width: 500, height: 800),
            destination: CGRect(x: 0, y: 0, width: 1_000, height: 1_200)
        )

        expect(scale == PDFPageRenderScale(x: 2, y: 1.5), "scale should map PDF bounds into destination")
    }

    private static func testPageScaleIgnoresOrigins() {
        let scale = PDFPageRenderGeometry.pageScale(
            bounds: CGRect(x: 50, y: 100, width: 300, height: 400),
            destination: CGRect(x: 20, y: 30, width: 600, height: 1_000)
        )

        expect(scale == PDFPageRenderScale(x: 2, y: 2.5), "scale should depend on sizes, not origins")
    }

    private static func testPageScaleRejectsInvalidRects() {
        expect(
            PDFPageRenderGeometry.pageScale(
                bounds: .zero,
                destination: CGRect(x: 0, y: 0, width: 100, height: 100)
            ) == nil,
            "empty PDF bounds should be rejected"
        )
        expect(
            PDFPageRenderGeometry.pageScale(
                bounds: CGRect(x: 0, y: 0, width: 100, height: 100),
                destination: CGRect(x: 0, y: 0, width: 0, height: 100)
            ) == nil,
            "empty destination should be rejected"
        )
    }
}
