import CoreGraphics
import Foundation

@main
enum PDFExamGradingSupportTests {
    static func main() {
        testClampsStampAnchor()
        testSerializesClampedAnchor()

        print("PDFExamGradingSupportTests: 8 passed")
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
