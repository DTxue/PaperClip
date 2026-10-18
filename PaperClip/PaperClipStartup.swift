import SwiftData

@MainActor
enum PaperClipStartup {
    private static var bootstrappedContainerID: ObjectIdentifier?

    static func runOnce(
        for container: ModelContainer,
        isPersistentStore: Bool
    ) {
        let containerID = ObjectIdentifier(container)
        guard bootstrappedContainerID != containerID else { return }
        bootstrappedContainerID = containerID
        guard isPersistentStore else { return }

        do {
            guard LegacyMistakeDataCleanup.canRemoveLegacyFiles() else {
                assertionFailure("错题数据未清理：未找到可验证的清理前备份。")
                return
            }
            try LegacyMistakeDataCleanup.removeLegacyFiles()
            LegacyMistakeDataCleanup.markCompleted()
        } catch {
            assertionFailure("错题文件清理失败：\(error.localizedDescription)")
        }

        VocabularyMaintenance.backfillMemoryStateDeckIDs(in: container)
    }
}
