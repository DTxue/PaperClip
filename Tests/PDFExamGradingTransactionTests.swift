import Foundation
import SwiftData

private enum TestError: Error {
    case persistFailed
}

extension ModelContext {
    @discardableResult
    func deleteExamGradeMarks(attemptID: UUID) throws -> Int {
        var descriptor = FetchDescriptor<ExamGradeMark>(
            predicate: #Predicate<ExamGradeMark> { mark in
                mark.attemptId == attemptID
            }
        )
        descriptor.propertiesToFetch = ExamGradeMark.deletionPropertiesToFetch
        return try deleteFetched(descriptor)
    }
}

@main
enum PDFExamGradingTransactionTests {
    @MainActor
    static func main() throws {
        try testBeginSubmissionDoesNotChangeStatusWhenPersistFails()
        try testBeginSubmissionMarksSubmittedAfterPersistSucceeds()
        try testBeginSubmissionRejectsAlreadySubmittedAttemptsBeforePersisting()
        try testFinishGradingRequiresSubmittedAttempt()
        try testFinishGradingReplacesOldMarksAndMarksAttemptGraded()
        try testRecordGradingFailureKeepsSubmittedAndDoesNotDowngradeGraded()

        print("PDFExamGradingTransactionTests: 22 passed")
    }

    @MainActor
    private static func testBeginSubmissionDoesNotChangeStatusWhenPersistFails() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let attempt = makeAttempt(status: .inProgress)
        context.insert(attempt)
        try context.save()

        do {
            try PDFExamGradingTransaction.beginSubmission(
                attempt: attempt,
                in: context,
                persistPendingChanges: { throw TestError.persistFailed }
            )
            fail("beginSubmission should rethrow pending persistence errors")
        } catch TestError.persistFailed {
            expect(attempt.status == ExamAttemptStatus.inProgress.rawValue, "failed pending save keeps in-progress status")
            expect(attempt.submittedAt == nil, "failed pending save does not set submittedAt")
        }
    }

    @MainActor
    private static func testBeginSubmissionMarksSubmittedAfterPersistSucceeds() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let attempt = makeAttempt(status: .inProgress)
        context.insert(attempt)
        try context.save()

        var didPersistPendingChanges = false
        try PDFExamGradingTransaction.beginSubmission(
            attempt: attempt,
            in: context,
            persistPendingChanges: { didPersistPendingChanges = true }
        )

        expect(didPersistPendingChanges, "beginSubmission flushes pending drawings before status change")
        expect(attempt.status == ExamAttemptStatus.submitted.rawValue, "successful beginSubmission marks submitted")
        expect(attempt.submittedAt != nil, "successful beginSubmission sets submittedAt")
    }

    @MainActor
    private static func testBeginSubmissionRejectsAlreadySubmittedAttemptsBeforePersisting() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let attempt = makeAttempt(status: .submitted)
        context.insert(attempt)
        try context.save()

        var didPersistPendingChanges = false
        do {
            try PDFExamGradingTransaction.beginSubmission(
                attempt: attempt,
                in: context,
                persistPendingChanges: { didPersistPendingChanges = true }
            )
            fail("already submitted attempts should be rejected")
        } catch PDFExamGradingTransactionError.alreadySubmittedOrGraded {
            expect(!didPersistPendingChanges, "already submitted attempts are rejected before pending persistence")
            expect(attempt.status == ExamAttemptStatus.submitted.rawValue, "already submitted status remains unchanged")
        }
    }

    @MainActor
    private static func testFinishGradingRequiresSubmittedAttempt() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let attempt = makeAttempt(status: .inProgress)
        context.insert(attempt)
        try context.save()

        do {
            try PDFExamGradingTransaction.finishGrading(
                items: [try makeGradingItem(pageIndex: 0, isCorrect: true)],
                attempt: attempt,
                sourceDocumentID: attempt.sourceDocumentId,
                in: context
            )
            fail("finishGrading should reject in-progress attempts")
        } catch PDFExamGradingTransactionError.notSubmitted {
            let marks = try fetchGradeMarks(attemptID: attempt.id, in: context)
            expect(marks.isEmpty, "finishGrading does not create marks for in-progress attempts")
            expect(attempt.status == ExamAttemptStatus.inProgress.rawValue, "in-progress attempt remains unchanged")
        }
    }

    @MainActor
    private static func testFinishGradingReplacesOldMarksAndMarksAttemptGraded() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let attempt = makeAttempt(status: .submitted)
        context.insert(attempt)
        context.insert(ExamGradeMark(
            sourceDocumentId: attempt.sourceDocumentId,
            attemptId: attempt.id,
            pageIndex: 0,
            isCorrect: true,
            normalizedAnchor: "0.5,0.5"
        ))
        try context.save()

        try PDFExamGradingTransaction.finishGrading(
            items: [try makeGradingItem(pageIndex: 1, isCorrect: false)],
            attempt: attempt,
            sourceDocumentID: attempt.sourceDocumentId,
            in: context
        )

        let marks = try fetchGradeMarks(attemptID: attempt.id, in: context)
        expect(attempt.status == ExamAttemptStatus.graded.rawValue, "finishGrading marks attempt graded")
        expect(marks.count == 1, "finishGrading replaces old grade marks")
        expect(marks.first?.pageIndex == 1, "finishGrading writes new page index")
        expect(marks.first?.isCorrect == false, "finishGrading writes correctness")
        expect(marks.first?.normalizedAnchor == "0.96,0.04", "finishGrading clamps and serializes stamp anchor")
    }

    @MainActor
    private static func testRecordGradingFailureKeepsSubmittedAndDoesNotDowngradeGraded() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let submittedAttempt = makeAttempt(status: .submitted)
        let gradedAttempt = makeAttempt(status: .graded)
        context.insert(submittedAttempt)
        context.insert(gradedAttempt)
        try context.save()

        try PDFExamGradingTransaction.recordGradingFailure(attempt: submittedAttempt, in: context)
        try PDFExamGradingTransaction.recordGradingFailure(attempt: gradedAttempt, in: context)

        expect(submittedAttempt.status == ExamAttemptStatus.submitted.rawValue, "failed grading keeps submitted attempts submitted")
        expect(gradedAttempt.status == ExamAttemptStatus.graded.rawValue, "failed grading does not downgrade graded attempts")
    }

    @MainActor
    private static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            PDFDocumentItem.self,
            HandwritingLayer.self,
            ExamAttempt.self,
            ExamHandwritingLayer.self,
            ExamGradeMark.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static func makeAttempt(status: ExamAttemptStatus) -> ExamAttempt {
        ExamAttempt(
            sourceDocumentId: UUID(),
            sourceDocumentTitle: "期中试卷",
            generatedPDFFileName: "\(UUID().uuidString).pdf",
            selectedPageIndices: [0, 1],
            status: status.rawValue
        )
    }

    private static func makeGradingItem(pageIndex: Int, isCorrect: Bool) throws -> AIExamGradingItem {
        let json = """
        {
          "pageIndex": \(pageIndex),
          "questionNumber": "1",
          "isCorrect": \(isCorrect),
          "stampAnchor": { "x": 2, "y": -1 },
          "confidence": 0.8
        }
        """
        return try JSONDecoder().decode(AIExamGradingItem.self, from: Data(json.utf8))
    }

    @MainActor
    private static func fetchGradeMarks(
        attemptID: UUID,
        in context: ModelContext
    ) throws -> [ExamGradeMark] {
        try context.fetch(FetchDescriptor<ExamGradeMark>(
            predicate: #Predicate<ExamGradeMark> { mark in
                mark.attemptId == attemptID
            }
        ))
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
