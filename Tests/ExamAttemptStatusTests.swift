import Foundation

@main
struct ExamAttemptStatusTests {
    static func main() {
        testSubmitEligibility()
        testUnknownStatusIsNotSubmittable()
        testTerminalStatus()

        print("ExamAttemptStatusTests: 5 passed")
    }

    private static func testSubmitEligibility() {
        expect(ExamAttemptStatus.inProgress.canSubmit)
        expect(ExamAttemptStatus.canSubmit(ExamAttemptStatus.inProgress.rawValue))
        expect(!ExamAttemptStatus.submitted.canSubmit)
        expect(!ExamAttemptStatus.graded.canSubmit)
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
