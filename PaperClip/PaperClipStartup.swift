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
                assertionFailure("旧错题文件未清理：未找到可验证的清理前备份。")
                return
            }
            try LegacyMistakeDataCleanup.removeLegacyFiles()
            let referencedAttachmentNames = Set(
                try container.mainContext.fetch(FetchDescriptor<MistakeAttachment>())
                    .map(\.fileName)
            )
            try MistakeAttachmentStore.recoverInterruptedDeletions(
                referencedFileNames: referencedAttachmentNames
            )
            LegacyMistakeDataCleanup.markCompleted()
        } catch {
            assertionFailure("旧错题文件清理失败：\(error.localizedDescription)")
        }

        VocabularyMaintenance.backfillMemoryStateDeckIDs(in: container)
        PDFExamRecordMaintenance.repairLinks(in: container)
    }
}

@MainActor
enum PDFExamRecordMaintenance {
    static func repairLinks(in container: ModelContainer) {
        do {
            try PDFExamArchiveStore.restoreMissingArchives(in: container.mainContext)
            try container.mainContext.repairAllExamAttemptLinks()
        } catch {
            assertionFailure("考试记录关联修复失败：\(error.localizedDescription)")
        }
    }
}
