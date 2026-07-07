import SwiftUI
import UniformTypeIdentifiers

extension View {
    func vocabularyTextFileImporter(
        isPresented: Binding<Bool>,
        onCompletion: @escaping (Result<[URL], Error>) -> Void
    ) -> some View {
        fileImporter(
            isPresented: isPresented,
            allowedContentTypes: [.plainText, .commaSeparatedText],
            allowsMultipleSelection: false,
            onCompletion: onCompletion
        )
    }
}

struct VocabularyImportTextInputSection: View {
    @Binding var preset: VocabularyImportPreset
    @Binding var text: String
    let title: String
    let onChooseFile: () -> Void

    var body: some View {
        Section {
            Picker("格式", selection: $preset) {
                ForEach(VocabularyImportPreset.allCases) { p in
                    Text(p.title).tag(p)
                }
            }
            Button("选择文件…", systemImage: "doc", action: onChooseFile)
            TextEditor(text: $text)
                .frame(minHeight: 180)
                .font(.body.monospaced())
                .accessibilityLabel("待导入文本")
        } header: {
            Text(title)
        } footer: {
            Text("Tab 分隔：每行以 Tab 键隔开单词与释义；每两行一组：奇数行单词、偶数行释义；CSV：每行以逗号隔开，支持引号转义。多字段顺序为：单词、释义、音标、例句、词性、标签、备注、可接受答案。")
        }
    }
}

struct VocabularyImportPreviewSection: View {
    let title: String
    let text: String
    let result: VocabularyImportResult
    let limit: Int
    var showsExample = false
    var showsEmptyState = false

    var body: some View {
        Section(title) {
            if showsEmptyState && text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ContentUnavailableView("没有文本", systemImage: "doc.text")
            } else {
                ForEach(result.rows.prefix(limit)) { row in
                    VocabularyImportPreviewRow(row: row, showsExample: showsExample)
                }
                if result.rows.count > limit {
                    Text("仅预览前 \(limit) 行，共 \(result.rows.count) 行。")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct VocabularyImportPreviewRow: View {
    let row: VocabularyImportRow
    let showsExample: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(row.term.isEmpty ? "（空）" : row.term)
                    .font(.headline)
                Spacer()
                if let error = row.error {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            Text(row.definition.isEmpty ? "（空）" : row.definition)
                .foregroundStyle(.secondary)
            if showsExample && !row.example.isEmpty {
                Text(row.example)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
