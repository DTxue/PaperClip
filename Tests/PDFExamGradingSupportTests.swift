import CoreGraphics
import Foundation

@main
enum PDFExamGradingSupportTests {
    static func main() {
        testClampsStampAnchor()
        testSerializesClampedAnchor()
        testNormalizesPercentageStampAnchor()
        testNormalizesPixelStampAnchor()
        testNormalizesMixedModelCoordinateSpacesByPageAxis()
        testNormalizesDefinitePixelCoordinatesByPage()

        print("PDFExamGradingSupportTests: 13 passed")
    }

    private static func testClampsStampAnchor() {
        let low = PDFExamGradingSupport.clampedStampAnchor(CGPoint(x: -1, y: 0))
        expect(abs(low.x - 0.04) < 0.0001, "clamps low x")
        expect(abs(low.y - 0.04) < 0.0001, "clamps low y")

        let high = PDFExamGradingSupport.clampedStampAnchor(CGPoint(x: 2, y: 3))
        expect(abs(high.x - 0.96) < 0.0001, "clamps high x")
        expect(abs(high.y - 0.96) < 0.0001, "clamps high y")

        let middle = PDFExamGradingSupport.clampedStampAnchor(CGPoint(x: 0.42, y: 0.58))
        expect(abs(middle.x - 0.42) < 0.0001, "keeps middle x")
        expect(abs(middle.y - 0.58) < 0.0001, "keeps middle y")
    }

    private static func testSerializesClampedAnchor() {
        expect(
            PDFExamGradingSupport.normalizedStampAnchorString(CGPoint(x: -1, y: 2)) == "0.04,0.96",
            "serializes clamped anchor"
        )
        expect(
            PDFExamGradingSupport.normalizedStampAnchorString(x: 0.42, y: 0.58) == "0.42,0.58",
            "serializes x/y anchor"
        )
    }

    private static func testNormalizesPercentageStampAnchor() {
        expect(
            PDFExamGradingSupport.normalizedStampAnchorString(x: 0.42, y: 58) == "0.42,0.58",
            "converts a percentage y coordinate without moving an already-normalized x coordinate"
        )
    }

    private static func testNormalizesPixelStampAnchor() {
        expect(
            PDFExamGradingSupport.normalizedStampAnchorString(
                x: 1_260,
                y: 1_000,
                pagePixelSize: CGSize(width: 1_400, height: 2_000)
            ) == "0.9,0.5",
            "converts page pixel coordinates before clamping"
        )
        expect(
            PDFExamGradingSupport.normalizedStampAnchorString(
                x: 70,
                y: 1_000,
                pagePixelSize: CGSize(width: 1_400, height: 2_000)
            ) == "0.05,0.5",
            "uses one coordinate system for both axes when either axis is pixel-based"
        )
    }

    private static func testNormalizesMixedModelCoordinateSpacesByPageAxis() {
        let anchors = [
            PDFExamGradingSupport.RawStampAnchor(pageIndex: 0, x: 0.404, y: 83),
            PDFExamGradingSupport.RawStampAnchor(pageIndex: 0, x: 0.1, y: 193),
            PDFExamGradingSupport.RawStampAnchor(pageIndex: 0, x: 0.391, y: 888)
        ]

        let normalized = PDFExamGradingSupport.normalizedStampAnchorStrings(
            anchors,
            pagePixelSizes: [0: CGSize(width: 1_400, height: 1_982)]
        )

        expect(
            normalized == ["0.404,0.083", "0.1,0.193", "0.391,0.888"],
            "normalizes each page axis consistently when the model mixes normalized x with 0...1000 y"
        )
    }

    private static func testNormalizesDefinitePixelCoordinatesByPage() {
        let anchors = [
            PDFExamGradingSupport.RawStampAnchor(pageIndex: 0, x: 1_260, y: 1_000),
            PDFExamGradingSupport.RawStampAnchor(pageIndex: 0, x: 70, y: 200)
        ]

        let normalized = PDFExamGradingSupport.normalizedStampAnchorStrings(
            anchors,
            pagePixelSizes: [0: CGSize(width: 1_400, height: 2_000)]
        )

        expect(
            normalized == ["0.9,0.5", "0.05,0.1"],
            "keeps actual image-pixel fallback when one page coordinate exceeds the 0...1000 model space"
        )
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError(message, file: file, line: line)
        }
    }
}
