import Foundation
import PencilKit

@main
struct DrawingDataSupportTests {
    static func main() {
        testEmptyAndInvalidDataDecodeToNoVisibleDrawing()
        testEmptyDrawingRoundTrip()

        print("DrawingDataSupportTests: 3 passed")
    }

    private static func testEmptyAndInvalidDataDecodeToNoVisibleDrawing() {
        expect(DrawingDataSupport.drawing(from: Data()) == nil)
        expect(DrawingDataSupport.drawing(from: Data([0, 1, 2])) == nil)
    }

    private static func testEmptyDrawingRoundTrip() {
        let data = DrawingDataSupport.emptyData()
        let drawing = DrawingDataSupport.drawingOrEmpty(from: data)
        expect(!DrawingDataSupport.hasInk(drawing))
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError("Expectation failed", file: file, line: line)
        }
    }
}
