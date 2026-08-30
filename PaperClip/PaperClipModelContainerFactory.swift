import SwiftData

struct PaperClipLaunchStore {
    let container: ModelContainer
    let isPersistent: Bool
    let startupError: AppAlert?
}

enum PaperClipModelContainerFactory {
    static func makeLaunchStore() -> PaperClipLaunchStore {
        do {
            let cleanupBackupURL = try LegacyMistakeDataCleanup.prepareSafetyBackupIfNeeded()
            return PaperClipLaunchStore(
                container: try PaperClipStore.makeContainer(),
                isPersistent: true,
                startupError: cleanupBackupURL.map { _ in
                    AppAlert(
                        title: "旧错题清理备份已生成",
                        message: "旧版错题数据清理前已完成整库备份。可在“设置 → 数据备份”中分享并长期保存。"
                    )
                }
            )
        } catch let persistentError {
            do {
                return PaperClipLaunchStore(
                    container: try PaperClipStore.makeContainer(isStoredInMemoryOnly: true),
                    isPersistent: false,
                    startupError: AppAlert(
                        title: "本地数据库不可用",
                        message: """
                        应用已进入临时模式，本次运行的数据不会持久保存，后台修复和识别已暂停。\
                        请重新启动应用；如问题持续，请先备份应用数据。\
                        原因：\(persistentError.localizedDescription)
                        """
                    )
                )
            } catch {
                fatalError("无法创建数据库容器：\(error.localizedDescription)")
            }
        }
    }

    static func makeTemporaryLaunchStore(startupError: AppAlert) -> PaperClipLaunchStore {
        do {
            return PaperClipLaunchStore(
                container: try PaperClipStore.makeContainer(isStoredInMemoryOnly: true),
                isPersistent: false,
                startupError: startupError
            )
        } catch {
            fatalError("无法创建安全临时数据库：\(error.localizedDescription)")
        }
    }

}
