import Foundation

@MainActor
final class DebouncedAction {
    private var task: Task<Void, Never>?

    func schedule(
        after delay: Duration,
        action: @escaping @MainActor () -> Void
    ) {
        task?.cancel()
        task = Task { @MainActor in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            action()
            task = nil
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
