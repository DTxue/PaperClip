import Foundation

@main
enum ReviewSubmissionGenerationRequestTests {
    static func main() {
        testSortsSelectedPagesForRendering()
        testReportsEmptySelection()
        print("ReviewSubmissionGenerationRequestTests: 2 passed")
    }

    private static func testSortsSelectedPagesForRendering() {
        let request = ReviewSubmissionGenerationRequest(
            pdfURL: URL(fileURLWithPath: "/tmp/review.pdf"),
            selectedPages: [3, 1, 2],
            drawings: [1: Data([1, 2, 3])]
        )

        assertEqual(request.pageIndices, [1, 2, 3])
        assertEqual(request.isEmpty, false)
    }

    private static func testReportsEmptySelection() {
        let request = ReviewSubmissionGenerationRequest(
            pdfURL: URL(fileURLWithPath: "/tmp/review.pdf"),
            selectedPages: [],
            drawings: [:]
        )

        assertEqual(request.pageIndices, [])
        assertEqual(request.isEmpty, true)
    }

    private static func assertEqual<T: Equatable>(
        _ actual: T,
        _ expected: T,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard actual == expected else {
            fatalError("Expected \(expected), got \(actual)", file: file, line: line)
        }
    }
}
