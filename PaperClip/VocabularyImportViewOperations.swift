import SwiftData
import SwiftUI

extension VocabularyDeckCreateView {
    func loadFile(_ fileResult: Result<[URL], Error>) {
        startVocabularyImportFileLoad(
            fileResult,
            cancel: { fileLoadTaskSlot.cancel() },
            start: { fileLoadTaskSlot.start($0) },
            isCurrent: { fileLoadTaskSlot.isCurrent($0) },
            finish: { fileLoadTaskSlot.finish($0) },
            onSuccess: { file in
                applyVocabularyImportedTextFile(
                    file,
                    text: $text,
                    sourceName: $sourceName,
                    preset: $preset,
                    defaultTitle: applyDefaultTitle
                )
            },
            onFailure: { error in
                alert = AppAlert(title: "无法读取文件", error: error)
            }
        )
    }

    func applyDefaultTitle(_ defaultTitle: String) {
        guard !defaultTitle.isEmpty else { return }

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || titleWasAutoFilled {
            title = defaultTitle
            titleWasAutoFilled = true
        }
    }

    func create() {
        do {
            try VocabularyImportOperations.createDeck(
                in: modelContext,
                kind: kind,
                title: title,
                dailyNewLimit: dailyNewLimit,
                desiredRetention: desiredRetention,
                sourceName: sourceName,
                preset: preset,
                importResult: importResult
            )
            dismiss()
        } catch {
            modelContext.rollback()
            alert = AppAlert(title: "创建失败", error: error)
        }
    }
}

extension VocabularyImportView {
    func loadFile(_ fileResult: Result<[URL], Error>) {
        startVocabularyImportFileLoad(
            fileResult,
            cancel: { fileLoadTaskSlot.cancel() },
            start: { fileLoadTaskSlot.start($0) },
            isCurrent: { fileLoadTaskSlot.isCurrent($0) },
            finish: { fileLoadTaskSlot.finish($0) },
            onSuccess: { file in
                applyVocabularyImportedTextFile(
                    file,
                    text: $text,
                    sourceName: $sourceName,
                    preset: $preset
                )
            },
            onFailure: { error in
                alert = AppAlert(title: "无法读取文件", error: error)
            }
        )
    }

    func importRows() {
        do {
            try VocabularyImportOperations.importRows(
                into: deck,
                in: modelContext,
                sourceName: sourceName,
                preset: preset,
                duplicateStrategy: duplicateStrategy,
                importResult: importResult
            )
            dismiss()
        } catch {
            modelContext.rollback()
            alert = AppAlert(title: "导入失败", error: error)
        }
    }
}
