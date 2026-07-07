import Foundation

struct ReviewSubmissionGenerationRequest: Sendable {
    let pdfURL: URL
    let selectedPages: Set<Int>
    let drawings: [Int: Data]

    var pageIndices: [Int] {
        selectedPages.sorted()
    }

    var isEmpty: Bool {
        selectedPages.isEmpty
    }
}
