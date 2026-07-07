import SwiftUI

struct VocabularyFolderCreateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var alert: AppAlert?

    var body: some View {
        Form {
            Section("文件夹") {
                TextField("名称", text: $title)
            }
        }
        .navigationTitle("创建文件夹")
        .navigationBarTitleDisplayMode(.inline)
        .editSheetToolbar(
            confirmTitle: "创建",
            isConfirmDisabled: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            onCancel: { dismiss() },
            onConfirm: create
        )
        .appAlert($alert)
    }

    private func create() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        do {
            modelContext.insert(VocabularyFolder(title: trimmedTitle))
            try modelContext.saveOrRollbackIfNeeded()
            dismiss()
        } catch {
            alert = AppAlert(title: "无法创建文件夹", error: error)
        }
    }
}

struct VocabularyDeckFolderPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let deck: VocabularyDeckRowData
    let folders: [VocabularyFolderRowData]
    let onSelect: (UUID?) -> Void

    var body: some View {
        List {
            Section {
                Button {
                    onSelect(nil)
                    dismiss()
                } label: {
                    Label("未归档", systemImage: "tray")
                }
            }

            Section("文件夹") {
                if folders.isEmpty {
                    ContentUnavailableView(
                        "还没有文件夹",
                        systemImage: "folder",
                        description: Text("请先在 ENG 首页创建文件夹。")
                    )
                    .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    ForEach(folders) { folder in
                        Button {
                            onSelect(folder.id)
                            dismiss()
                        } label: {
                            HStack {
                                Label(folder.title, systemImage: "folder")
                                Spacer()
                                if deck.folderID == folder.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("移动「\(deck.title)」")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
            }
        }
    }
}
