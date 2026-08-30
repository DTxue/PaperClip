import SwiftUI
import SwiftData

@main
struct PaperClipApp: App {
    private let container: ModelContainer
    private let isPersistentStore: Bool
    private let startupError: AppAlert?

    init() {
        let interruptedRestoreError: PaperClipBackupError?
        do {
            try PaperClipDataBackupService.recoverInterruptedRestoreIfNeeded()
            interruptedRestoreError = nil
        } catch let error as PaperClipBackupError {
            interruptedRestoreError = error
        } catch {
            interruptedRestoreError = .restoreRollbackFailed(error.localizedDescription)
        }

        let backupAlert: AppAlert?
        if interruptedRestoreError != nil {
            backupAlert = nil
        } else {
            do {
                backupAlert = try PaperClipDataBackupService.createScheduledBackupIfNeeded() != nil
                    ? AppAlert(
                        title: "备份已生成",
                        message: "一致性备份已生成。可在“设置 → 数据备份”中分享或保存。"
                    )
                    : nil
            } catch {
                backupAlert = AppAlert(title: "生成备份失败", error: error)
            }
        }

        let restoreError: AppAlert?
        let canOpenPersistentStore: Bool
        if let interruptedRestoreError {
            restoreError = AppAlert(title: "恢复原数据失败", error: interruptedRestoreError)
            canOpenPersistentStore = false
        } else {
            do {
                restoreError = try PaperClipDataBackupService.applyPendingRestoreIfNeeded()
                    ? AppAlert(title: "数据已恢复", message: "已从备份恢复 PaperClip 数据。")
                    : nil
                canOpenPersistentStore = true
            } catch let error as PaperClipBackupError {
                restoreError = AppAlert(title: "恢复备份失败", error: error)
                canOpenPersistentStore = !error.preventsPersistentStoreOpening
            } catch {
                restoreError = AppAlert(title: "恢复备份失败", error: error)
                canOpenPersistentStore = true
            }
        }

        let launchStore: PaperClipLaunchStore
        if canOpenPersistentStore {
            launchStore = PaperClipModelContainerFactory.makeLaunchStore()
        } else {
            launchStore = PaperClipModelContainerFactory.makeTemporaryLaunchStore(
                startupError: restoreError ?? AppAlert(
                    title: "持久数据库已暂停",
                    message: "恢复回滚失败，为避免覆盖原数据，本次仅以临时模式启动。"
                )
            )
        }
        container = launchStore.container
        isPersistentStore = launchStore.isPersistent
        startupError = restoreError ?? backupAlert ?? launchStore.startupError
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(startupError: startupError)
                .task {
                    PaperClipStartup.runOnce(
                        for: container,
                        isPersistentStore: isPersistentStore
                    )
                }
        }
        .modelContainer(container)
    }
}
