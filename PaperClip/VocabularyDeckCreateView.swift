import SwiftData
import SwiftUI

struct VocabularyDeckCreateView: View {
    let kind: VocabularyDeckKind

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State var title = ""
    @State var titleWasAutoFilled = false
    @State var dailyNewLimit = 15
    @State var desiredRetention = 0.9

    @State var text = ""
    @State var preset: VocabularyImportPreset = .tab
    @State var isFileImporterPresented = false
    @State var sourceName = "粘贴文本"
    @State var fileLoadTaskSlot = ViewTaskSlot()
    @State var alert: AppAlert?

    var importResult: VocabularyImportResult {
        VocabularyTextImporter.parse(text, format: preset.format)
    }

    init(kind: VocabularyDeckKind = .word) {
        self.kind = kind
    }

    var body: some View {
        let importResult = importResult
        let summary = importResult.summary

        Form {
            Section(kind.collectionName) {
                TextField("名称", text: Binding(
                    get: { title },
                    set: {
                        title = $0
                        titleWasAutoFilled = false
                    }
                ))
            }
            Section("记忆设置") {
                Stepper(kind.dailyNewLimitText(dailyNewLimit), value: $dailyNewLimit, in: 1...100)
                Slider(value: $desiredRetention, in: 0.8...0.97, step: 0.01) {
                    Text("目标保持率")
                } minimumValueLabel: {
                    Text("80%")
                } maximumValueLabel: {
                    Text("97%")
                }
                Text("目标保持率 \(Int(desiredRetention * 100))%。保持率越高，复习频率越高。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            VocabularyImportTextInputSection(
                preset: $preset,
                text: $text,
                title: "导入\(kind.itemName)",
                kind: kind,
                onChooseFile: { isFileImporterPresented = true }
            )

            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VocabularyImportPreviewSection(
                    title: "预览 · \(preset.title)",
                    text: text,
                    result: importResult,
                    limit: 50
                )
            }
        }
        .navigationTitle("创建\(kind.collectionName)")
        .navigationBarTitleDisplayMode(.inline)
        .editSheetToolbar(
            confirmTitle: summary.createConfirmTitle(),
            isConfirmDisabled: !summary.canCreateDeck(title: title),
            onCancel: { dismiss() },
            onConfirm: create
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
