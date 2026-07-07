import Foundation

enum MainActorScheduler {
    static func async(_ operation: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            operation()
        }
    }
}
