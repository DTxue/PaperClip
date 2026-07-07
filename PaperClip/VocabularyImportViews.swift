import SwiftUI
import SwiftData

struct VocabularyImportView: View {
    let deck: VocabularyDeck

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State var text = ""
    @State var preset: VocabularyImportPreset = .tab
    @State var duplicateStrategy: VocabularyDuplicateStrategy = .merge
    @State var isFileImporterPresented = false
    @State var sourceName = "粘贴文本"
    @State var fileLoadTaskSlot = ViewTaskSlot()
    @State var alert: AppAlert?

    init(deck: VocabularyDeck) {
        self.deck = deck
    }

    var importResult: VocabularyImportResult {
        VocabularyTextImporter.parse(text, format: preset.format)
    }

    var body: some View {
        let importResult = importResult
        let summary = importResult.summary

        Form {
            VocabularyImportTextInputSection(
                preset: $preset,
                text: $text,
                title: "文本",
                onChooseFile: { isFileImporterPresented = true }
            )

            Section("重复项") {
                Picker("处理方式", selection: $duplicateStrategy) {
                    ForEach(VocabularyDuplicateStrategy.allCases) { strategy in
                        Text(strategy.rawValue).tag(strategy)
                    }
                }
            }

            VocabularyImportPreviewSection(
                title: "预览 · \(preset.title)",
                text: text,
                result: importResult,
                limit: 100,
                showsExample: true,
                showsEmptyState: true
            )
        }
        .navigationTitle("导入单词")
        .navigationBarTitleDisplayMode(.inline)
        .editSheetToolbar(
            confirmTitle: summary.importConfirmTitle(),
            isConfirmDisabled: !summary.hasValidRows,
            onCancel: { dismiss() },
            onConfirm: importRows
        )
        .vocabularyTextFileImporter(
            isPresented: $isFileImporterPresented
        ) { fileResult in
            loadFile(fileResult)
        }
        .onDisappear {
            fileLoadTaskSlot.cancel()
        }
        .appAlert($alert)
    }
}
