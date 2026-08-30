import Foundation

struct PDFExamPageProgress: Equatable, Hashable {
    let pageIndices: [Int]
    let submittedPageIndices: Set<Int>
    let gradedPageIndices: Set<Int>

    init(pageIndices: [Int], submissions: [ExamPageSubmission]) {
        self.pageIndices = pageIndices
        let validPages = Set(pageIndices)
        submittedPageIndices = Set(submissions.compactMap { submission in
            guard validPages.contains(submission.pageIndex),
                  ExamPageSubmissionStatus(rawValue: submission.status)?.countsAsSubmitted == true
            else { return nil }
            return submission.pageIndex
        })
        gradedPageIndices = Set(submissions.compactMap { submission in
            guard validPages.contains(submission.pageIndex),
                  ExamPageSubmissionStatus(rawValue: submission.status)?.countsAsGraded == true
            else { return nil }
            return submission.pageIndex
        })
    }

    var nextUnsubmittedPageIndex: Int? {
        pageIndices.first { !submittedPageIndices.contains($0) }
    }

    var isFullySubmitted: Bool {
        !pageIndices.isEmpty && submittedPageIndices.isSuperset(of: pageIndices)
    }

    var isFullyGraded: Bool {
        !pageIndices.isEmpty && gradedPageIndices.isSuperset(of: pageIndices)
    }

    func canWrite(pageIndex: Int) -> Bool {
        pageIndex == nextUnsubmittedPageIndex
    }

    func isAwaitingGrading(pageIndex: Int) -> Bool {
        submittedPageIndices.contains(pageIndex)
            && !gradedPageIndices.contains(pageIndex)
    }
}
