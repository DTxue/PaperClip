import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @State private var selection: SettingsCategory? = .appearance

    var body: some View {
        PaperClipNavigationSplitView {
            SettingsSidebarView(selection: $selection)
        } detail: {
            switch selection {
            case .appearance: AppearanceSettingsView()
            case .fsrs:       FSRSExplanationView()
            case .ai:         AISettingsView()
            case .diary:      DiarySettingsView()
            case .writing:    WritingSettingsView()
            case .data:       DataBackupSettingsView()
            case .about:      AboutSettingsView()
            case nil:         ContentUnavailableView("请选择设置项", systemImage: "gearshape")
            }
        }
    }
}

private extension UTType {
    static let paperClipBackup = UTType(exportedAs: "com.paperclip.backup", conformingTo: .package)
}

private struct PaperClipBackupTransfer: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .paperClipBackup) { item in
            SentTransferredFile(item.url)
        }
    }
}

private struct DataBackupSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var backupURL: URL? = PaperClipDataBackupService.completedBackupURL()
    @State private var isCreatingBackup = false
    @State private var isStagingRestore = false
    @State private var isImporterPresented = false
    @State private var alert: AppAlert?

    var body: some View {
        Form {
            Section("导出整库备份") {
                Text("为避免多窗口或后台任务在复制期间改动数据，备份会在下次完全启动时、数据库打开前生成并校验。备份包含数据库、图片、词集、日记和写作等数据，也会保留旧版本遗留文件。")

                Button {
                    createBackup()
                } label: {
                    Label(isCreatingBackup ? "正在准备备份..." : "准备生成备份", systemImage: "archivebox")
                }
                .disabled(isCreatingBackup || isStagingRestore)

                if let backupURL {
                    ShareLink(
                        item: PaperClipBackupTransfer(url: backupURL),
                        preview: SharePreview("PaperClip 数据备份")
                    ) {
                        Label("分享/保存备份", systemImage: "square.and.arrow.up")
                    }
                    Text("请把备份保存到 Files、iCloud Drive 或 Mac。不要只留在 App 临时目录中。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("从备份恢复") {
                Text("恢复会先暂存备份，并在下次启动时、数据库打开前替换本机数据。恢复前建议先导出当前数据备份。")

                Button {
                    isImporterPresented = true
                } label: {
                    Label(isStagingRestore ? "正在准备恢复..." : "选择备份文件", systemImage: "arrow.down.doc")
                }
                .disabled(isCreatingBackup || isStagingRestore)
            }
        }
        .navigationTitle("数据备份")
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.paperClipBackup, .package, .folder],
            allowsMultipleSelection: false,
            onCompletion: handleImport
        )
        .appAlert($alert)
    }

    @MainActor
    private func createBackup() {
        guard !isCreatingBackup else { return }
        let container = modelContext.container
        guard container.configurations.contains(where: {
            !$0.isStoredInMemoryOnly
        }) else {
            alert = AppAlert(
                title: "当前无法生成备份",
                message: "PaperClip 正在临时数据模式中。请重新启动应用并确认本地数据库可用后再备份。"
            )
            return
        }

        isCreatingBackup = true

        do {
            if modelContext.hasChanges {
                try modelContext.save()
            }
        } catch {
            isCreatingBackup = false
            alert = AppAlert(title: "保存当前数据失败", error: error)
            return
        }

        PaperClipDataBackupService.scheduleBackupOnNextLaunch()
        isCreatingBackup = false
        alert = AppAlert(
            title: "备份已安排",
            message: "请先完成其他窗口中的编辑，然后完全退出并重新打开 PaperClip。备份会在数据库打开前自动生成；之后回到这里即可分享或保存。"
        )
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            isStagingRestore = true
            Task {
                do {
                    try await Task.detached(priority: .userInitiated) {
                        try PaperClipDataBackupService.stageRestore(from: url)
                    }.value

                    await MainActor.run {
                        isStagingRestore = false
                        alert = AppAlert(
                            title: "备份已准备恢复",
                            message: "请完全退出并重新打开 PaperClip。恢复会在下次启动时生效。"
                        )
                    }
                } catch {
                    await MainActor.run {
                        isStagingRestore = false
                        alert = AppAlert(title: "准备恢复失败", error: error)
                    }
                }
            }
        case .failure(let error):
            alert = AppAlert(title: "选择备份失败", error: error)
        }
    }
}
