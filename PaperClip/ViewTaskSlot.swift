import Foundation

struct ViewTaskSlot {
    private(set) var id = UUID()
    private var task: Task<Void, Never>?

    var isRunning: Bool {
        task != nil
    }

    mutating func start(_ operation: @escaping @MainActor (UUID) async -> Void) -> UUID {
        cancel()
        let taskID = UUID()
        id = taskID
        task = Task { @MainActor in
            await operation(taskID)
        }
        return taskID
    }

    func isCurrent(_ taskID: UUID) -> Bool {
        id == taskID
    }

    mutating func finish(_ taskID: UUID) {
        guard isCurrent(taskID) else { return }
        task = nil
    }

    mutating func cancel() {
        task?.cancel()
        task = nil
        id = UUID()
    }
}

typealias DiaryTaskSlot = ViewTaskSlot
