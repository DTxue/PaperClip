import Foundation

@main
struct MistakeRecognitionQueueTests {
    static func main() throws {
        try testUserInitiatedWorkRunsBeforeRecovery()
        try testDuplicateCardIsIgnoredWhilePendingOrProcessing()
        try testRecoveryWorkUsesIndependentConcurrencyLimit()
        print("MistakeRecognitionQueueTests: 3 passed")
    }

    private static func testUserInitiatedWorkRunsBeforeRecovery() throws {
        var queue = MistakeRecognitionQueue()
        let recoveryID = UUID()
        let userID = UUID()

        queue.enqueue(cardID: recoveryID, imagePath: "recovery.png", priority: .recovery)
        queue.enqueue(cardID: userID, imagePath: "user.png", priority: .userInitiated)

        let first = try require(queue.startNext(maxConcurrent: 2, maxConcurrentRecovery: 1))
        expect(first.cardID == userID)
        expect(first.priority == .userInitiated)
    }

    private static func testDuplicateCardIsIgnoredWhilePendingOrProcessing() throws {
        var queue = MistakeRecognitionQueue()
        let id = UUID()

        queue.enqueue(cardID: id, imagePath: "first.png", priority: .userInitiated)
        queue.enqueue(cardID: id, imagePath: "second.png", priority: .userInitiated)

        let first = try require(queue.startNext(maxConcurrent: 2, maxConcurrentRecovery: 1))
        expect(first.imagePath == "first.png")

        queue.enqueue(cardID: id, imagePath: "third.png", priority: .userInitiated)
        expect(queue.startNext(maxConcurrent: 2, maxConcurrentRecovery: 1) == nil)

        queue.finish(first)
        queue.enqueue(cardID: id, imagePath: "fourth.png", priority: .userInitiated)
        let second = try require(queue.startNext(maxConcurrent: 2, maxConcurrentRecovery: 1))
        expect(second.imagePath == "fourth.png")
    }

    private static func testRecoveryWorkUsesIndependentConcurrencyLimit() throws {
        var queue = MistakeRecognitionQueue()
        let firstRecoveryID = UUID()
        let secondRecoveryID = UUID()
        let userID = UUID()

        queue.enqueue(cardID: firstRecoveryID, imagePath: "recovery-1.png", priority: .recovery)
        queue.enqueue(cardID: secondRecoveryID, imagePath: "recovery-2.png", priority: .recovery)

        let firstRecovery = try require(queue.startNext(maxConcurrent: 2, maxConcurrentRecovery: 1))
        expect(firstRecovery.cardID == firstRecoveryID)
        expect(queue.startNext(maxConcurrent: 2, maxConcurrentRecovery: 1) == nil)

        queue.enqueue(cardID: userID, imagePath: "user.png", priority: .userInitiated)
        let userItem = try require(queue.startNext(maxConcurrent: 2, maxConcurrentRecovery: 1))
        expect(userItem.cardID == userID)

        queue.finish(firstRecovery)
        queue.finish(userItem)
        let secondRecovery = try require(queue.startNext(maxConcurrent: 2, maxConcurrentRecovery: 1))
        expect(secondRecovery.cardID == secondRecoveryID)
    }
}

private func require<T>(_ value: T?) throws -> T {
    guard let value else {
        throw TestFailure("Expected non-nil value")
    }
    return value
}

private func expect(_ condition: @autoclosure () -> Bool) {
    if !condition() {
        fatalError("Expectation failed")
    }
}

private struct TestFailure: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
