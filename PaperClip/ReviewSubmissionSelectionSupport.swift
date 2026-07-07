import Foundation

struct ReviewSubmissionPageSelection: Equatable {
    let pageCount: Int
    let answeredPageSet: Set<Int>
    let selectedPages: Set<Int>
}

enum ReviewSubmissionSelectionSupport {
    static let maximumPageCount = 8

    static func makeSelection(
        pageCount: Int,
        drawingPageIndices: some Sequence<Int>,
        hasVisibleDrawing: (Int) -> Bool,
        maximumPageCount: Int = Self.maximumPageCount
    ) -> ReviewSubmissionPageSelection {
        let validRange = 0..<max(pageCount, 0)
        let answeredPages = drawingPageIndices
            .filter { validRange.contains($0) && hasVisibleDrawing($0) }
            .sorted()
        let initialPages = answeredPages.isEmpty
            ? Array(0..<min(max(pageCount, 0), 1))
            : Array(answeredPages.prefix(maximumPageCount))

        return ReviewSubmissionPageSelection(
            pageCount: max(pageCount, 0),
            answeredPageSet: Set(answeredPages),
            selectedPages: Set(initialPages)
        )
    }
}
