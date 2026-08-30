import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("Test failed: \(message)\n", stderr)
        Foundation.exit(1)
    }
}

private struct TestLayer {
    let pageIndex: Int
    let updatedAt: Date
    let id: String
}

@main
struct PDFWorkspaceCoreTests {
    static func main() {
        testLatestLayersByPage()
        testAnswerLayerWritePlanKeepsOnlyChangedPages()
        testAnswerLayerWritePlanCompletesUnchangedPendingPages()
        testExamActivationDefaultsEnableWriting()
        testExamGradingActionState()
        testToolbarAllowsSubmittedAttemptToRequestGrading()

        print("PDFWorkspaceCoreTests: 26 passed")
    }

    private static func testLatestLayersByPage() {
        let base = Date(timeIntervalSince1970: 1_000)
        let oldPageOne = TestLayer(pageIndex: 1, updatedAt: base, id: "old-1")
        let latestPageOne = TestLayer(pageIndex: 1, updatedAt: base.addingTimeInterval(20), id: "latest-1")
        let pageTwo = TestLayer(pageIndex: 2, updatedAt: base.addingTimeInterval(10), id: "latest-2")

        let result = latestLayersByPage(
            [latestPageOne, pageTwo, oldPageOne],
            pageIndex: \.pageIndex,
            updatedAt: \.updatedAt
        )

        expect(result.latest[1]?.id == "latest-1", "keeps newest layer for page 1")
        expect(result.latest[2]?.id == "latest-2", "keeps independent page layers")
        expect(result.duplicates.map(\.id) == ["old-1"], "reports older duplicate layers")
    }

    private static func testAnswerLayerWritePlanKeepsOnlyChangedPages() {
        let plan = PDFAnswerLayerWritePlan.make(
            currentDrawingDataByPage: [
                0: Data([1]),
                1: Data([2])
            ],
            pendingDrawingDataByPage: [
                0: Data([1]),
                1: Data([9]),
                2: Data([3])
            ]
        )

        expect(plan.hasChanges, "changed pending drawings should require persistence")
        expect(plan.changedDrawingDataByPage == [
            1: Data([9]),
            2: Data([3])
        ], "write plan keeps only pages with changed drawing data")
        expect(plan.completedPageIndices == Set([0, 1, 2]), "all pending pages complete after successful flush")
    }

    private static func testAnswerLayerWritePlanCompletesUnchangedPendingPages() {
        let plan = PDFAnswerLayerWritePlan.make(
            currentDrawingDataByPage: [
                0: Data([1])
            ],
            pendingDrawingDataByPage: [
                0: Data([1])
            ]
        )

        expect(!plan.hasChanges, "unchanged pending drawings should not require persistence")
        expect(plan.changedDrawingDataByPage.isEmpty, "unchanged pages are not written")
        expect(plan.completedPageIndices == Set([0]), "unchanged pending pages can still be removed from pending state")
    }

    private static func testExamActivationDefaultsEnableWriting() {
        expect(PDFExamActivationDefaults.isWritingEnabled, "exam attempts should enter writing mode by default")
        expect(PDFExamActivationDefaults.isDrawingVisible, "exam attempts should show drawings by default")
    }

    private static func testExamGradingActionState() {
        let inProgress = PDFExamGradingActionState(status: .inProgress, isSubmitting: false)
        expect(inProgress.isEnabled, "in-progress attempts can submit for grading")
        expect(inProgress.title == "交卷", "in-progress attempts use submit copy")
        expect(inProgress.systemImage == "checkmark.seal", "in-progress attempts use submit icon")

        let attemptID = UUID()
        let progress = PDFExamPageProgress(
            pageIndices: [0, 1],
            submissions: [
                ExamPageSubmission(
                    sourceDocumentId: UUID(),
                    attemptId: attemptID,
                    pageIndex: 0,
                    status: ExamPageSubmissionStatus.submitted.rawValue
                )
            ]
        )
        let retryCurrentPage = PDFExamGradingActionState(
            status: .inProgress,
            isSubmitting: false,
            pageProgress: progress,
            currentPageIndex: 0
        )
        expect(retryCurrentPage.title == "重试第 1 页", "failed submitted pages can be retried before the full exam is submitted")
        expect(retryCurrentPage.systemImage == "arrow.clockwise.circle", "page grading retries use the retry icon")

        let retryLockedPage = PDFExamGradingActionState(
            status: .inProgress,
            isSubmitting: false,
            pageProgress: progress,
            currentPageIndex: 1,
            resumeTarget: .retryGrading(pageIndex: 0)
        )
        expect(retryLockedPage.title == "重试第 1 页", "scrolling cannot bypass a pending page grading retry")

        let submitted = PDFExamGradingActionState(status: .submitted, isSubmitting: false)
        expect(submitted.isEnabled, "submitted attempts can retry grading")
        expect(submitted.title == "重新批阅", "submitted attempts use retry copy")
        expect(submitted.systemImage == "arrow.clockwise.circle", "submitted attempts use retry icon")

        let submitting = PDFExamGradingActionState(status: .inProgress, isSubmitting: true)
        expect(!submitting.isEnabled, "submitting attempts disable grading actions")

        let graded = PDFExamGradingActionState(status: .graded, isSubmitting: false)
        expect(!graded.isEnabled, "graded attempts cannot request grading")
    }

    private static func testToolbarAllowsSubmittedAttemptToRequestGrading() {
        let submitted = makeAttempt(status: .submitted)
        let submittedSnapshot = PDFWorkspaceToolbarSnapshot(
            activeAttempt: submitted,
            hasAttempts: true,
            isSubmittingExam: false,
            isWritingEnabled: false,
            isDrawingVisible: true
        )
        expect(submittedSnapshot.canSubmitExam, "submitted attempts should allow retrying grading")
        expect(submittedSnapshot.submitExamTitle == "重新批阅", "submitted attempts should use retry copy")

        let graded = makeAttempt(status: .graded)
        let gradedSnapshot = PDFWorkspaceToolbarSnapshot(
            activeAttempt: graded,
            hasAttempts: true,
            isSubmittingExam: false,
            isWritingEnabled: false,
            isDrawingVisible: true
        )
        expect(!gradedSnapshot.canSubmitExam, "graded attempts should not allow grading retry")
    }

    private static func makeAttempt(status: ExamAttemptStatus) -> ExamAttempt {
        ExamAttempt(
            sourceDocumentId: UUID(),
            sourceDocumentTitle: "期中试卷",
            generatedPDFFileName: "\(UUID().uuidString).pdf",
            selectedPageIndices: [0],
            status: status.rawValue
        )
    }

}
