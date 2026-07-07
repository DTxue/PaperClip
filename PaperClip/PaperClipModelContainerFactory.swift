import SwiftData

struct PaperClipLaunchStore {
    let container: ModelContainer
    let startupError: AppAlert?
}

enum PaperClipModelContainerFactory {
    static func makeLaunchStore() -> PaperClipLaunchStore {
        let schema = makeSchema()
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return PaperClipLaunchStore(
                container: try ModelContainer(
                    for: schema,
                    configurations: [configuration]
                ),
                startupError: nil
            )
        } catch let persistentError {
            do {
                let fallback = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                return PaperClipLaunchStore(
                    container: try ModelContainer(
                        for: schema,
                        configurations: [fallback]
                    ),
                    startupError: AppAlert(
                        title: "本地数据库不可用",
                        message: """
                        应用已进入临时模式，本次运行的数据不会持久保存。\
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

    private static func makeSchema() -> Schema {
        Schema([
            PDFDocumentItem.self,
            HandwritingLayer.self,
            ExamAttempt.self,
            ExamHandwritingLayer.self,
            ExamGradeMark.self,
            MistakeCard.self,
            ExportRecord.self,
            MistakePracticeLayer.self,
            VocabularyFolder.self,
            VocabularyDeck.self,
            VocabularyCard.self,
            VocabularyMemoryState.self,
            VocabularyReviewLog.self,
            VocabularyStudySession.self,
            VocabularyTestDraft.self,
            VocabularyHandwritingAttempt.self,
            VocabularyImportBatch.self,
            VocabularyDistractorCache.self,
            DiaryEntry.self,
            KnowledgeItem.self,
            WritingPrompt.self,
            WritingDraft.self,
            WritingReview.self
        ])
    }
}
