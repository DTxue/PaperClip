import SwiftUI

@MainActor
func applyVocabularyImportedTextFile(
    _ file: VocabularyImportedTextFile,
    text: Binding<String>,
    sourceName: Binding<String>,
    preset: Binding<VocabularyImportPreset>,
    defaultTitle: ((String) -> Void)? = nil
) {
    text.wrappedValue = file.text
    sourceName.wrappedValue = file.fileName
    defaultTitle?(file.defaultTitle)
    if file.isCSV {
        preset.wrappedValue = .csv
    }
}

@MainActor
func startVocabularyImportFileLoad(
    _ fileResult: Result<[URL], Error>,
    cancel: () -> Void,
    start: (@escaping @MainActor (UUID) async -> Void) -> UUID,
    isCurrent: @escaping (UUID) -> Bool,
    finish: @escaping (UUID) -> Void,
    onSuccess: @escaping @MainActor (VocabularyImportedTextFile) -> Void,
    onFailure: @escaping @MainActor (Error) -> Void
) {
    cancel()
    do {
        guard let url = try fileResult.get().first else { return }
        _ = start { taskID in
            await loadVocabularyImportFile(
                from: url,
                isCurrent: { isCurrent(taskID) },
                onSuccess: onSuccess,
                onFailure: onFailure
            )
            finish(taskID)
        }
    } catch {
        onFailure(error)
    }
}

private func loadVocabularyImportFile(
    from url: URL,
    isCurrent: @escaping @MainActor () -> Bool,
    onSuccess: @escaping @MainActor (VocabularyImportedTextFile) -> Void,
    onFailure: @escaping @MainActor (Error) -> Void
) async {
    do {
        let file = try await VocabularyTextFileLoader.load(from: url)
        try Task.checkCancellation()
        guard await isCurrent() else { return }
        await onSuccess(file)
    } catch is CancellationError {
        return
    } catch {
        guard !Task.isCancelled else { return }
        guard await isCurrent() else { return }
        await onFailure(error)
    }
}
