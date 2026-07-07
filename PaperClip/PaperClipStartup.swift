import SwiftData

@MainActor
enum PaperClipStartup {
    private static var bootstrappedContainerID: ObjectIdentifier?

    static func runOnce(for container: ModelContainer) {
        let containerID = ObjectIdentifier(container)
        guard bootstrappedContainerID != containerID else { return }
        bootstrappedContainerID = containerID

        VocabularyMaintenance.backfillMemoryStateDeckIDs(in: container)
        PDFExamRecordMaintenance.repairLinks(in: container)
        // 将 ModelContainer 注入识别服务，补跑上次未完成的识别任务。
        MistakeCardRecognitionService.shared.modelContainer = container
        MistakeCardRecognitionService.shared.resumeUnfinished()
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
