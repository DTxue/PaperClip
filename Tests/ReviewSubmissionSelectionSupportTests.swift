import Foundation

@main
struct ReviewSubmissionSelectionSupportTests {
    static func main() {
        selectsAnsweredPagesFirst()
        fallsBackToFirstPageWhenNoAnswersExist()
        ignoresOutOfRangeAndInvisibleDrawings()
        print("ReviewSubmissionSelectionSupportTests: 3 passed")
    }

    private static func selectsAnsweredPagesFirst() {
        let selection = ReviewSubmissionSelectionSupport.makeSelection(
            pageCount: 12,
            drawingPageIndices: [9, 1, 3, 5],
            hasVisibleDrawing: { _ in true },
            maximumPageCount: 3
        )

        assertEqual(selection.pageCount, 12)
        assertEqual(selection.answeredPageSet, [1, 3, 5, 9])
        assertEqual(selection.selectedPages, [1, 3, 5])
    }

    private static func fallsBackToFirstPageWhenNoAnswersExist() {
        let selection = ReviewSubmissionSelectionSupport.makeSelection(
            pageCount: 4,
            drawingPageIndices: [],
            hasVisibleDrawing: { _ in true },
            maximumPageCount: 8
        )

        assertEqual(selection.answeredPageSet, [])
        assertEqual(selection.selectedPages, [0])
    }

    private static func ignoresOutOfRangeAndInvisibleDrawings() {
        let selection = ReviewSubmissionSelectionSupport.makeSelection(
            pageCount: 3,
            drawingPageIndices: [-1, 0, 1, 2, 3],
            hasVisibleDrawing: { $0 != 1 },
            maximumPageCount: 8
        )

        assertEqual(selection.answeredPageSet, [0, 2])
        assertEqual(selection.selectedPages, [0, 2])
    }

    private static func assertEqual<T: Equatable>(
        _ actual: T,
        _ expected: T,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        if actual != expected {
            fatalError("Expected \(expected), got \(actual)", file: file, line: line)
        }
    }
}
