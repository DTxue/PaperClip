import Foundation

@main
enum PDFExamResumePolicyTests {
    static func main() {
        testSavedDraftResumesTheSamePage()
        testSubmittedPageRetriesGradingWithoutUnlockingNextPage()
        testGradedPageUnlocksOnlyTheNextPage()
        testFullyGradedRoundHasNoSelectableExamPage()
        testDraftAfterGradedPrefixResumesInsteadOfSkippingAhead()
        testOutOfOrderLegacyGradingStillMarksCompletedPages()
        testFullDocumentDetectionUsesSourcePageCount()
        print("PDFExamResumePolicyTests: 25 passed")
    }

    private static func testFullDocumentDetectionUsesSourcePageCount() {
        expect(
            PDFExamResumePolicy.usesFullDocumentPages(
                selectedPageIndices: [0, 1, 2],
                sourcePageCount: 3
            ),
            "all source pages are recognized as a full-document exam"
        )
        expect(
            !PDFExamResumePolicy.usesFullDocumentPages(
                selectedPageIndices: [0, 1],
                sourcePageCount: 5
            ),
            "legacy leading-page selection is not mistaken for a full-document exam"
        )
    }

    private static func testOutOfOrderLegacyGradingStillMarksCompletedPages() {
        let attemptID = UUID()
        let pending = ExamPageSubmission(
            sourceDocumentId: UUID(),
            attemptId: attemptID,
            pageIndex: 0,
            status: ExamPageSubmissionStatus.submitted.rawValue
        )
        let laterGraded = ExamPageSubmission(
            sourceDocumentId: UUID(),
            attemptId: attemptID,
            pageIndex: 1,
            status: ExamPageSubmissionStatus.graded.rawValue
        )
        let decision = PDFExamResumePolicy.decide(
            pageIndices: [0, 1, 2],
            submissions: [pending, laterGraded],
            pagesWithAnswers: []
        )

        expect(decision.target == .retryGrading(pageIndex: 0), "earliest pending page remains the resume target")
        expect(decision.state(for: 1) == .graded, "legacy later grading remains visibly completed")
        expect(!decision.canSelectForExam(pageIndex: 1), "legacy completed page cannot be repeated")
    }

    private static func testDraftAfterGradedPrefixResumesInsteadOfSkippingAhead() {
        let graded = ExamPageSubmission(
            sourceDocumentId: UUID(),
            attemptId: UUID(),
            pageIndex: 0,
            status: ExamPageSubmissionStatus.graded.rawValue
        )
        let decision = PDFExamResumePolicy.decide(
            pageIndices: [0, 1, 2],
            submissions: [graded],
            pagesWithAnswers: Set([1])
        )

        expect(decision.target == .resumeDraft(pageIndex: 1), "unfinished page resumes after graded prefix")
        expect(decision.state(for: 0) == .graded, "completed prefix remains locked")
        expect(decision.state(for: 1) == .resumeDraft, "saved page is the resume target")
        expect(decision.state(for: 2) == .locked, "resume does not skip to a later page")
    }

    private static func testFullyGradedRoundHasNoSelectableExamPage() {
        let attemptID = UUID()
        let submissions = [0, 1].map { pageIndex in
            ExamPageSubmission(
                sourceDocumentId: UUID(),
                attemptId: attemptID,
                pageIndex: pageIndex,
                status: ExamPageSubmissionStatus.graded.rawValue
            )
        }
        let decision = PDFExamResumePolicy.decide(
            pageIndices: [0, 1],
            submissions: submissions,
            pagesWithAnswers: Set([0, 1])
        )

        expect(decision.target == .roundCompleted, "fully graded round has no resume target")
        expect(decision.state(for: 0) == .graded, "first completed page stays graded")
        expect(decision.state(for: 1) == .graded, "last completed page stays graded")
        expect(!decision.canSelectForExam(pageIndex: 1), "completed pages never reopen for examination")
    }

    private static func testGradedPageUnlocksOnlyTheNextPage() {
        let submission = ExamPageSubmission(
            sourceDocumentId: UUID(),
            attemptId: UUID(),
            pageIndex: 0,
            status: ExamPageSubmissionStatus.graded.rawValue
        )
        let decision = PDFExamResumePolicy.decide(
            pageIndices: [0, 1, 2],
            submissions: [submission],
            pagesWithAnswers: []
        )

        expect(decision.target == .startNextPage(pageIndex: 1), "graded page advances to the next page")
        expect(decision.state(for: 0) == .graded, "graded page is shown as completed")
        expect(!decision.canSelectForExam(pageIndex: 0), "graded page cannot be selected for another exam")
        expect(decision.state(for: 1) == .ready, "only the next page is ready")
        expect(decision.state(for: 2) == .locked, "later pages remain locked")
    }

    private static func testSubmittedPageRetriesGradingWithoutUnlockingNextPage() {
        let submission = ExamPageSubmission(
            sourceDocumentId: UUID(),
            attemptId: UUID(),
            pageIndex: 0,
            status: ExamPageSubmissionStatus.submitted.rawValue
        )
        let decision = PDFExamResumePolicy.decide(
            pageIndices: [0, 1],
            submissions: [submission],
            pagesWithAnswers: Set([0])
        )

        expect(decision.target == .retryGrading(pageIndex: 0), "submitted page retries grading")
        expect(decision.state(for: 0) == .retryGrading, "submitted answer cannot be edited again")
        expect(decision.canSelectForExam(pageIndex: 0), "pending grading page remains selectable for retry")
        expect(decision.state(for: 1) == .locked, "next page waits for grading completion")
    }

    private static func testSavedDraftResumesTheSamePage() {
        let decision = PDFExamResumePolicy.decide(
            pageIndices: [0, 1],
            submissions: [],
            pagesWithAnswers: Set([0])
        )

        expect(decision.target == .resumeDraft(pageIndex: 0), "saved draft resumes its page")
        expect(decision.state(for: 0) == .resumeDraft, "draft page remains selectable")
        expect(decision.state(for: 1) == .locked, "later pages remain locked")
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
