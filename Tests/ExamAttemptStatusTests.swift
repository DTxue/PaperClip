import Foundation

@main
struct ExamAttemptStatusTests {
    static func main() {
        testSubmitEligibility()
        testGradingRequestEligibility()
        testUnknownStatusIsNotSubmittable()
        testTerminalStatus()

        print("ExamAttemptStatusTests: 8 passed")
    }

    private static func testSubmitEligibility() {
        expect(ExamAttemptStatus.inProgress.canSubmit)
        expect(ExamAttemptStatus.canSubmit(ExamAttemptStatus.inProgress.rawValue))
        expect(!ExamAttemptStatus.submitted.canSubmit)
        expect(!ExamAttemptStatus.graded.canSubmit)
    }

    private static func testGradingRequestEligibility() {
        expect(ExamAttemptStatus.inProgress.canRequestGrading)
        expect(ExamAttemptStatus.submitted.canRequestGrading)
        expect(!ExamAttemptStatus.graded.canRequestGrading)
    }

    private static func testUnknownStatusIsNotSubmittable() {
        expect(!ExamAttemptStatus.canSubmit("legacy_unknown"))
    }

    private static func testTerminalStatus() {
        expect(!ExamAttemptStatus.inProgress.isTerminal)
        expect(ExamAttemptStatus.graded.isTerminal)
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError("Expectation failed", file: file, line: line)
        }
    }
}
