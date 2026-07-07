import CoreGraphics
import Foundation

@main
struct PDFGradeStampIndexTests {
    static func main() {
        testReturnsStampsForVisiblePages()
        testRemoveAllClearsIndex()
        print("PDFGradeStampIndexTests: 2 passed")
    }

    private static func testReturnsStampsForVisiblePages() {
        var index = PDFGradeStampIndex()
        let first = makeStamp(pageIndex: 0, confidence: 0.9)
        let second = makeStamp(pageIndex: 1, confidence: 0.8)
        let third = makeStamp(pageIndex: 1, confidence: 0.7)
        index.updateIfNeeded([first, second, third])

        let visible = Set(index.stamps(on: [1]).map(\.id))
        expect(visible == [second.id, third.id])
    }

    private static func testRemoveAllClearsIndex() {
        var index = PDFGradeStampIndex()
        index.updateIfNeeded([makeStamp(pageIndex: 0, confidence: 0.9)])
        index.removeAll()

        expect(index.stamps(on: [0]).isEmpty)
    }

    private static func makeStamp(pageIndex: Int, confidence: Double) -> PDFGradeStamp {
        PDFGradeStamp(
            id: UUID(),
            pageIndex: pageIndex,
            isCorrect: confidence > 0.75,
            normalizedAnchor: CGPoint(x: 0.5, y: 0.5),
            confidence: confidence
        )
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
