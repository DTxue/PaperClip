import Foundation

@main
enum MistakeRecognitionStatusSupportTests {
    static func main() {
        testUnfinishedStatuses()
        testRecoveryStatus()

        print("MistakeRecognitionStatusSupportTests: 9 passed")
    }

    private static func testUnfinishedStatuses() {
        expect(MistakeRecognitionStatusSupport.isUnfinished(RecognitionStatus.pending.rawValue))
        expect(MistakeRecognitionStatusSupport.isUnfinished(RecognitionStatus.processing.rawValue))
        expect(MistakeRecognitionStatusSupport.isUnfinished(RecognitionStatus.failed.rawValue))
        expect(!MistakeRecognitionStatusSupport.isUnfinished(RecognitionStatus.completed.rawValue))
        expect(!MistakeRecognitionStatusSupport.isUnfinished("legacy_unknown"))
    }

    private static func testRecoveryStatus() {
        expect(MistakeRecognitionStatusSupport.recoveryStatus(from: RecognitionStatus.pending.rawValue) == RecognitionStatus.pending.rawValue)
        expect(MistakeRecognitionStatusSupport.recoveryStatus(from: RecognitionStatus.processing.rawValue) == RecognitionStatus.pending.rawValue)
        expect(MistakeRecognitionStatusSupport.recoveryStatus(from: RecognitionStatus.failed.rawValue) == RecognitionStatus.pending.rawValue)
        expect(MistakeRecognitionStatusSupport.recoveryStatus(from: RecognitionStatus.completed.rawValue) == RecognitionStatus.completed.rawValue)
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
