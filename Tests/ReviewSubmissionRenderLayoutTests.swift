import CoreGraphics
import Foundation

@main
enum ReviewSubmissionRenderLayoutTests {
    static func main() {
        laysOutPagesWithFixedGap()
        rejectsOversizedStacks()
        ignoresInvalidPageGeometryInputs()

        print("ReviewSubmissionRenderLayoutTests: 3 passed")
    }

    private static func laysOutPagesWithFixedGap() {
        let layout = ReviewSubmissionRenderLayout.outputLayout(
            for: [
                ReviewSubmissionPageGeometry(
                    displayBounds: CGRect(x: 0, y: 0, width: 400, height: 300),
                    drawingBounds: CGRect(x: 0, y: 0, width: 400, height: 300)
                ),
                ReviewSubmissionPageGeometry(
                    displayBounds: CGRect(x: 0, y: 0, width: 800, height: 400),
                    drawingBounds: CGRect(x: 0, y: 0, width: 800, height: 400)
                )
            ]
        )

        assertEqual(layout?.outputSize.width, 1_600)
        assertEqual(layout?.pages.count, 2)
        assertEqual(layout?.pages[0].destination, CGRect(x: 0, y: 0, width: 1_600, height: 1_200))
        assertEqual(layout?.pages[1].destination, CGRect(x: 0, y: 1_212, width: 1_600, height: 800))
    }

    private static func rejectsOversizedStacks() {
        let tallPages = Array(
            repeating: ReviewSubmissionPageGeometry(
                displayBounds: CGRect(x: 0, y: 0, width: 100, height: 20_000),
                drawingBounds: CGRect(x: 0, y: 0, width: 100, height: 20_000)
            ),
            count: 4
        )

        assertEqual(ReviewSubmissionRenderLayout.outputLayout(for: tallPages), nil)
    }

    private static func ignoresInvalidPageGeometryInputs() {
        let layout = ReviewSubmissionRenderLayout.outputLayout(
            for: [
                ReviewSubmissionPageGeometry(
                    displayBounds: CGRect(x: 0, y: 0, width: 0, height: 300),
                    drawingBounds: CGRect(x: 0, y: 0, width: 0, height: 300)
                )
            ]
        )

        assertEqual(layout, nil)
    }

    private static func assertEqual<T: Equatable>(
        _ actual: T,
        _ expected: T,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        if actual != expected {
            fatalError("Expected \(expected), got \(String(describing: actual))", file: file, line: line)
        }
    }
}
