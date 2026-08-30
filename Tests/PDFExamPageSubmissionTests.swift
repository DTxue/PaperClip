import Foundation
import SwiftData

private enum PageSubmissionTestError: Error {
    case persistFailed
}

@main
enum PDFExamPageSubmissionTests {
    @MainActor
    static func main() throws {
        try testSubmittingPagesAdvancesProgressAndCompletesAttempt()
        try testFinishingPageGradingPreservesOtherPagesAndCompletesRound()
        try testFailedSaveAndDuplicateSubmissionDoNotCorruptProgress()
        try testNextPageWaitsForPreviousPageGrading()
        try testGradedPageCannotBeGradedAgain()

        print("PDFExamPageSubmissionTests: 31 passed")
    }

    @MainActor
    private static func testGradedPageCannotBeGradedAgain() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let attempt = makeAttempt(pageCount: 1)
        context.insert(attempt)
        try context.save()

        let submission = try PDFExamPageSubmissionTransaction.beginSubmission(
            attempt: attempt,
            pageIndex: 0,
            in: context,
            persistPendingChanges: {}
        )
        try PDFExamPageSubmissionTransaction.finishGrading(
            items: [try makeGradingItem(pageIndex: 0, questionNumber: "1", isCorrect: true)],
            targetPageIndex: 0,
            pagePixelSize: CGSize(width: 1_400, height: 2_000),
            submission: submission,
            attempt: attempt,
            in: context
        )

        do {
            try PDFExamPageSubmissionTransaction.finishGrading(
                items: [try makeGradingItem(pageIndex: 0, questionNumber: "2", isCorrect: false)],
                targetPageIndex: 0,
                pagePixelSize: CGSize(width: 1_400, height: 2_000),
                submission: submission,
                attempt: attempt,
                in: context
            )
            fail("graded page must remain read-only at the transaction boundary")
        } catch PDFExamPageSubmissionError.alreadyGraded {}

        let marks = try context.fetch(FetchDescriptor<ExamGradeMark>())
        expect(marks.count == 1, "regrading rejection preserves the original mark")
        expect(marks.first?.questionNumber == "1", "regrading rejection does not replace grading results")
        expect(submission.status == ExamPageSubmissionStatus.graded.rawValue, "completed submission remains graded")
    }

    @MainActor
    private static func testNextPageWaitsForPreviousPageGrading() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let attempt = makeAttempt(pageCount: 2)
        context.insert(attempt)
        try context.save()

        let first = try PDFExamPageSubmissionTransaction.beginSubmission(
            attempt: attempt,
            pageIndex: 0,
            in: context,
            persistPendingChanges: {}
        )
        do {
            _ = try PDFExamPageSubmissionTransaction.beginSubmission(
                attempt: attempt,
                pageIndex: 1,
                in: context,
                persistPendingChanges: {}
            )
            fail("next page must wait for previous page grading")
        } catch PDFExamPageSubmissionError.pageNotUnlocked {}

        let submissionsBeforeGrading = try context.fetchExamPageSubmissions(attemptID: attempt.id)
        expect(submissionsBeforeGrading.count == 1, "locked page creates no submission")

        try PDFExamPageSubmissionTransaction.finishGrading(
            items: [],
            targetPageIndex: 0,
            pagePixelSize: CGSize(width: 1_400, height: 2_000),
            submission: first,
            attempt: attempt,
            in: context
        )
        let second = try PDFExamPageSubmissionTransaction.beginSubmission(
            attempt: attempt,
            pageIndex: 1,
            in: context,
            persistPendingChanges: {}
        )
        expect(second.pageIndex == 1, "graded previous page unlocks the next page")
        let submissionsAfterUnlock = try context.fetchExamPageSubmissions(attemptID: attempt.id)
        expect(submissionsAfterUnlock.count == 2, "unlocked page becomes durable")
    }

    @MainActor
    private static func testFailedSaveAndDuplicateSubmissionDoNotCorruptProgress() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let attempt = makeAttempt(pageCount: 2)
        context.insert(attempt)
        try context.save()

        do {
            _ = try PDFExamPageSubmissionTransaction.beginSubmission(
                attempt: attempt,
                pageIndex: 0,
                in: context,
                persistPendingChanges: { throw PageSubmissionTestError.persistFailed }
            )
            fail("failed pending save must stop page submission")
        } catch PageSubmissionTestError.persistFailed {}

        let submissionsAfterFailure = try context.fetchExamPageSubmissions(attemptID: attempt.id)
        expect(submissionsAfterFailure.isEmpty, "failed save creates no submission")
        expect(attempt.status == ExamAttemptStatus.inProgress.rawValue, "failed save keeps the round in progress")

        _ = try PDFExamPageSubmissionTransaction.beginSubmission(
            attempt: attempt,
            pageIndex: 0,
            in: context,
            persistPendingChanges: {}
        )
        do {
            _ = try PDFExamPageSubmissionTransaction.beginSubmission(
                attempt: attempt,
                pageIndex: 0,
                in: context,
                persistPendingChanges: {}
            )
            fail("the same page must not be submitted twice")
        } catch PDFExamPageSubmissionError.alreadySubmitted {}

        let submissionsAfterDuplicate = try context.fetchExamPageSubmissions(attemptID: attempt.id)
        expect(submissionsAfterDuplicate.count == 1, "duplicate submission keeps one durable record")
        expect(attempt.status == ExamAttemptStatus.inProgress.rawValue, "duplicate rejection does not complete the round")
    }

    @MainActor
    private static func testFinishingPageGradingPreservesOtherPagesAndCompletesRound() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let attempt = makeAttempt(pageCount: 2)
        context.insert(attempt)
        try context.save()

        let first = try PDFExamPageSubmissionTransaction.beginSubmission(
            attempt: attempt,
            pageIndex: 0,
            in: context,
            persistPendingChanges: {}
        )
        try PDFExamPageSubmissionTransaction.finishGrading(
            items: [try makeGradingItem(pageIndex: 0, questionNumber: "1", isCorrect: true)],
            targetPageIndex: 0,
            pagePixelSize: CGSize(width: 1_400, height: 2_000),
            submission: first,
            attempt: attempt,
            in: context
        )

        let second = try PDFExamPageSubmissionTransaction.beginSubmission(
            attempt: attempt,
            pageIndex: 1,
            in: context,
            persistPendingChanges: {}
        )
        try PDFExamPageSubmissionTransaction.finishGrading(
            items: [try makeGradingItem(pageIndex: 0, questionNumber: "2", isCorrect: false)],
            targetPageIndex: 1,
            pagePixelSize: CGSize(width: 1_400, height: 2_000),
            submission: second,
            attempt: attempt,
            in: context
        )

        let marks = try context.fetch(FetchDescriptor<ExamGradeMark>(
            sortBy: [SortDescriptor(\.pageIndex)]
        ))
        let submissions = try context.fetchExamPageSubmissions(attemptID: attempt.id)
        let progress = PDFExamPageProgress(
            pageIndices: attempt.selectedPageIndices,
            submissions: submissions
        )
        expect(marks.count == 2, "grading a page preserves marks from earlier pages")
        expect(marks.map(\.pageIndex) == [0, 1], "single-image AI page zero maps to each real PDF page")
        expect(marks.map(\.questionNumber) == ["1", "2"], "each page keeps its own grading result")
        expect(progress.gradedPageIndices == Set([0, 1]), "both page submissions become graded")
        expect(progress.isFullyGraded, "all graded pages complete grading")
        expect(attempt.status == ExamAttemptStatus.graded.rawValue, "the round becomes graded after its last page")
    }

    @MainActor
    private static func testSubmittingPagesAdvancesProgressAndCompletesAttempt() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let attempt = makeAttempt(pageCount: 3)
        context.insert(attempt)
        try context.save()

        let first = try PDFExamPageSubmissionTransaction.beginSubmission(
            attempt: attempt,
            pageIndex: 0,
            in: context,
            persistPendingChanges: {}
        )

        var submissions = try context.fetchExamPageSubmissions(attemptID: attempt.id)
        var progress = PDFExamPageProgress(
            pageIndices: attempt.selectedPageIndices,
            submissions: submissions
        )
        expect(first.pageIndex == 0, "submission keeps the submitted page")
        expect(progress.submittedPageIndices == Set([0]), "submitted page is durable")
        expect(progress.nextUnsubmittedPageIndex == 1, "progress advances to the next page")
        expect(attempt.status == ExamAttemptStatus.inProgress.rawValue, "partial submission keeps the round in progress")

        try PDFExamPageSubmissionTransaction.finishGrading(
            items: [],
            targetPageIndex: 0,
            pagePixelSize: CGSize(width: 1_400, height: 2_000),
            submission: first,
            attempt: attempt,
            in: context
        )
        let second = try PDFExamPageSubmissionTransaction.beginSubmission(
            attempt: attempt,
            pageIndex: 1,
            in: context,
            persistPendingChanges: {}
        )
        try PDFExamPageSubmissionTransaction.finishGrading(
            items: [],
            targetPageIndex: 1,
            pagePixelSize: CGSize(width: 1_400, height: 2_000),
            submission: second,
            attempt: attempt,
            in: context
        )
        _ = try PDFExamPageSubmissionTransaction.beginSubmission(
            attempt: attempt,
            pageIndex: 2,
            in: context,
            persistPendingChanges: {}
        )

        submissions = try context.fetchExamPageSubmissions(attemptID: attempt.id)
        progress = PDFExamPageProgress(
            pageIndices: attempt.selectedPageIndices,
            submissions: submissions
        )
        expect(progress.isFullySubmitted, "all pages submitted completes answering")
        expect(progress.nextUnsubmittedPageIndex == nil, "completed rounds have no next page")
        expect(attempt.status == ExamAttemptStatus.submitted.rawValue, "last page submission marks the round submitted")
        expect(attempt.submittedAt != nil, "last page submission records completion time")
    }

    @MainActor
    private static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            PDFDocumentItem.self,
            ExamAttempt.self,
            ExamPageSubmission.self,
            ExamGradeMark.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static func makeGradingItem(
        pageIndex: Int,
        questionNumber: String,
        isCorrect: Bool
    ) throws -> AIExamGradingItem {
        let json = """
        {
          "pageIndex": \(pageIndex),
          "questionNumber": "\(questionNumber)",
          "isCorrect": \(isCorrect),
          "stampAnchor": { "x": 0.8, "y": 0.25 },
          "confidence": 0.9
        }
        """
        return try JSONDecoder().decode(AIExamGradingItem.self, from: Data(json.utf8))
    }

    private static func makeAttempt(pageCount: Int) -> ExamAttempt {
        ExamAttempt(
            sourceDocumentId: UUID(),
            sourceDocumentTitle: "整卷考试",
            generatedPDFFileName: "\(UUID().uuidString).pdf",
            selectedPageIndices: Array(0..<pageCount)
        )
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

    private static func fail(
        _ message: String,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Never {
        fatalError(message, file: file, line: line)
    }
}
