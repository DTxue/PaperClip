import Foundation

enum PDFExamResumeTarget: Equatable, Hashable {
    case resumeDraft(pageIndex: Int)
    case retryGrading(pageIndex: Int)
    case startNextPage(pageIndex: Int)
    case roundCompleted

    var pageIndex: Int? {
        switch self {
        case let .resumeDraft(pageIndex),
             let .retryGrading(pageIndex),
             let .startNextPage(pageIndex):
            return pageIndex
        case .roundCompleted:
            return nil
        }
    }
}

enum PDFExamResumePageState: Equatable, Hashable {
    case resumeDraft
    case retryGrading
    case ready
    case graded
    case locked

    var isSelectableForExam: Bool {
        switch self {
        case .resumeDraft, .retryGrading, .ready:
            return true
        case .graded, .locked:
            return false
        }
    }
}

struct PDFExamResumeDecision: Equatable {
    let target: PDFExamResumeTarget
    private let pageStates: [Int: PDFExamResumePageState]

    init(
        target: PDFExamResumeTarget,
        pageStates: [Int: PDFExamResumePageState]
    ) {
        self.target = target
        self.pageStates = pageStates
    }

    func state(for pageIndex: Int) -> PDFExamResumePageState? {
        pageStates[pageIndex]
    }

    func canSelectForExam(pageIndex: Int) -> Bool {
        state(for: pageIndex)?.isSelectableForExam == true
    }
}

struct PDFExamPageSelectionContext: Identifiable, Equatable {
    let attemptID: UUID
    let documentURL: URL
    let decision: PDFExamResumeDecision

    var id: UUID { attemptID }
}

enum PDFExamResumePolicy {
    static func usesFullDocumentPages(
        selectedPageIndices: [Int],
        sourcePageCount: Int
    ) -> Bool {
        sourcePageCount > 0
            && selectedPageIndices == Array(0..<sourcePageCount)
    }

    static func decide(
        pageIndices: [Int],
        submissions: [ExamPageSubmission],
        pagesWithAnswers: Set<Int>
    ) -> PDFExamResumeDecision {
        var submissionStatusByPage: [Int: ExamPageSubmissionStatus] = [:]
        for submission in submissions {
            guard pageIndices.contains(submission.pageIndex),
                  let status = ExamPageSubmissionStatus(rawValue: submission.status)
            else { continue }
            submissionStatusByPage[submission.pageIndex] = status
        }

        var states = Dictionary(
            uniqueKeysWithValues: pageIndices.map { ($0, PDFExamResumePageState.locked) }
        )
        for pageIndex in pageIndices where submissionStatusByPage[pageIndex] == .graded {
            states[pageIndex] = .graded
        }
        for pageIndex in pageIndices {
            switch submissionStatusByPage[pageIndex] {
            case .graded:
                states[pageIndex] = .graded
                continue
            case .submitted:
                states[pageIndex] = .retryGrading
                return PDFExamResumeDecision(
                    target: .retryGrading(pageIndex: pageIndex),
                    pageStates: states
                )
            case nil:
                let hasDraft = pagesWithAnswers.contains(pageIndex)
                states[pageIndex] = hasDraft ? .resumeDraft : .ready
                return PDFExamResumeDecision(
                    target: hasDraft
                        ? .resumeDraft(pageIndex: pageIndex)
                        : .startNextPage(pageIndex: pageIndex),
                    pageStates: states
                )
            }
        }

        return PDFExamResumeDecision(target: .roundCompleted, pageStates: states)
    }
}
