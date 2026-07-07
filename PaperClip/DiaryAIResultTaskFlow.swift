import SwiftUI

extension DiaryAIResultView {
    func startTask(
        text: String,
        state: Binding<SectionAIState>,
        draft: Binding<String>,
        processor: @escaping (String) async throws -> String,
        start: (@escaping @MainActor (UUID) async -> Void) -> UUID,
        isCurrent: @escaping (UUID) -> Bool,
        finish: @escaping (UUID) -> Void
    ) {
        state.wrappedValue = .loading
        _ = start { taskID in
            do {
                let result = try await processor(text)
                try Task.checkCancellation()
                guard isCurrent(taskID) else { return }
                draft.wrappedValue = result
                state.wrappedValue = .done
                finish(taskID)
            } catch is CancellationError {
                guard isCurrent(taskID) else { return }
                finish(taskID)
            } catch {
                guard !Task.isCancelled else { return }
                guard isCurrent(taskID) else { return }
                state.wrappedValue = .failed(error.localizedDescription)
                finish(taskID)
            }
        }
    }
}
