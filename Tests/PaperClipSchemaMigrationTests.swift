import Foundation
import SwiftData

@MainActor
@main
enum PaperClipSchemaMigrationTests {
    static func main() throws {
        let storeURL = try copiedLegacyStoreURL()
        defer { try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent()) }

        let container = try PaperClipStore.makeContainer(at: storeURL)
        try verifyEveryV1Model(in: container.mainContext)
        verifyRetiredModelsAreAbsentFromV6()
        let externalDataDirectory = storeURL.deletingLastPathComponent()
            .appendingPathComponent(".default_SUPPORT", isDirectory: true)
            .appendingPathComponent("_EXTERNAL_DATA", isDirectory: true)
        let remainingExternalFiles = try FileManager.default.contentsOfDirectory(
            at: externalDataDirectory,
            includingPropertiesForKeys: nil
        )
        expect(
            remainingExternalFiles.count == 2,
            "migration removes retired mistake, PDF/exam, and writing sidecars"
        )

        try verifyV2ToV6Migration()
        try verifyV6CompatibilityRoundTrip()

        print("PaperClipSchemaMigrationTests: active V1 data preserved; retired entities removed; V6 ready")
    }

    private static func verifyV6CompatibilityRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PaperClipV6Compatibility-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("default.store")
        let deckID = UUID()
        let drawing = externalFixtureData(marker: 0x31)

        do {
            let container = try PaperClipStore.makeContainer(at: storeURL)
            let context = container.mainContext
            let diary = DiaryEntry(date: .now)
            diary.learned = "现行日记"
            diary.aiLearned = "历史学习整理"
            diary.aiConfused = "历史困惑整理"
            diary.aiInspired = "历史灵感整理"
            diary.aiState = "done"
            context.insert(diary)
            let knowledge = KnowledgeItem(summary: "现行知识点", source: "learned", entry: diary)
            knowledge.aiExamPattern = "历史考点分析"
            context.insert(knowledge)
            context.insert(VocabularyDeck(id: deckID, title: "保留草稿的词集"))
            context.insert(VocabularyTestDraft(
                deckID: deckID,
                mode: "考试",
                payload: VocabularyTestDraftSavePayload(
                    batchSize: 5,
                    currentBatchIndex: 0,
                    currentQuestionIndex: 1,
                    currentDrawingData: drawing,
                    didFinishAnswering: false,
                    startedAt: .now,
                    batches: []
                )
            ))
            try context.save()
        }

        let reopened = try PaperClipStore.makeContainer(at: storeURL)
        let diary = try only(DiaryEntry.self, in: reopened.mainContext)
        expect(diary.learned == "现行日记", "reopening V6 preserves current diary content")
        expect(diary.aiLearned == "历史学习整理", "cleanup preserves hidden learned analysis")
        expect(diary.aiConfused == "历史困惑整理", "cleanup preserves hidden confused analysis")
        expect(diary.aiInspired == "历史灵感整理" && diary.aiState == "done", "cleanup preserves legacy diary result state")
        let knowledge = try only(KnowledgeItem.self, in: reopened.mainContext)
        expect(knowledge.aiExamPattern == "历史考点分析", "cleanup preserves hidden knowledge data")
        expect(knowledge.diaryEntry?.id == diary.id, "reopening V6 preserves the knowledge relationship")
        let draft = try only(VocabularyTestDraft.self, in: reopened.mainContext)
        expect(draft.deckID == deckID && draft.mode == "考试", "retired mode values remain readable in stored drafts")
        expect(draft.currentQuestionIndex == 1 && draft.currentDrawingData == drawing, "relocated compatibility model preserves external drawing data")
    }

    private static func verifyV2ToV6Migration() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PaperClipV2ToV6Tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("default.store")

        do {
            let schema = Schema(versionedSchema: PaperClipSchemaV2.self)
            let configuration = ModelConfiguration("PaperClip", schema: schema, url: storeURL)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            container.mainContext.insert(
                PaperClipSchemaV2.MistakeLibraryItem(
                    questionText: "V2 物理错题",
                    correctAnswer: "旧答案",
                    explanation: "旧解析",
                    subject: Subject.physics.rawValue,
                    status: .learning
                )
            )
            try container.mainContext.save()
        }

        let migratedContainer = try PaperClipStore.makeContainer(at: storeURL)
        try verifyRetiredModelsAreAbsentFromV6()
        _ = migratedContainer.mainContext
    }

    private static func copiedLegacyStoreURL() throws -> URL {
        guard let fixtureDirectory = ProcessInfo.processInfo.environment["PAPERCLIP_LEGACY_STORE_DIR"],
              !fixtureDirectory.isEmpty
        else {
            fatalError("PAPERCLIP_LEGACY_STORE_DIR must point to the extracted static V1 fixture")
        }

        let sourceDirectory = URL(fileURLWithPath: fixtureDirectory, isDirectory: true)
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PaperClipSchemaMigrationTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.copyItem(at: sourceDirectory, to: temporaryDirectory)

        let storeURL = temporaryDirectory.appendingPathComponent("default.store")
        expect(FileManager.default.fileExists(atPath: storeURL.path), "static fixture contains default.store")
        let externalDataDirectory = temporaryDirectory
            .appendingPathComponent(".default_SUPPORT", isDirectory: true)
            .appendingPathComponent("_EXTERNAL_DATA", isDirectory: true)
        let externalFiles = try FileManager.default.contentsOfDirectory(
            at: externalDataDirectory,
            includingPropertiesForKeys: nil
        )
        expect(externalFiles.count == 7, "static fixture contains all seven externalStorage sidecars")
        return storeURL
    }

    private static func verifyEveryV1Model(in context: ModelContext) throws {
        let folder = try only(VocabularyFolder.self, in: context)
        expect(folder.id == fixtureUUID(5) && folder.title == "V1 词汇文件夹", "keeps vocabulary folder")

        let deck = try only(VocabularyDeck.self, in: context)
        expect(deck.id == fixtureUUID(6) && deck.folderID == folder.id, "keeps vocabulary deck binding")
        expect(deck.dailyNewLimit == 12 && deck.desiredRetention == 0.92, "keeps deck settings")

        let card = try only(VocabularyCard.self, in: context)
        expect(card.id == fixtureUUID(7) && card.deckID == deck.id, "keeps vocabulary card binding")
        expect(card.term == "migration" && card.definition == "迁移", "keeps vocabulary content")
        expect(card.note == "V1 card", "keeps vocabulary note")

        let memory = try only(VocabularyMemoryState.self, in: context)
        expect(memory.cardID == card.id && memory.deckID == deck.id, "keeps memory state binding")
        expect(memory.stage == VocabularyMemoryStage.review.rawValue, "keeps memory stage")
        expect(memory.reviewCount == 7 && memory.lapseCount == 1, "keeps memory statistics")

        let reviewLog = try only(VocabularyReviewLog.self, in: context)
        expect(reviewLog.cardID == card.id && reviewLog.deckID == deck.id, "keeps review log binding")
        expect(reviewLog.rating == VocabularyReviewRating.good.rawValue, "keeps review rating")
        expect(reviewLog.responseKind == "handwriting", "keeps review response kind")

        let studySession = try only(VocabularyStudySession.self, in: context)
        expect(studySession.deckID == deck.id, "keeps study session binding")
        expect(studySession.totalCount == 1 && studySession.correctCount == 1, "keeps study metrics")
        expect(studySession.items.first?.cardID == card.id, "keeps serialized study items")

        let testDraft = try only(VocabularyTestDraft.self, in: context)
        expect(testDraft.deckID == deck.id && testDraft.currentQuestionIndex == 2, "keeps test draft progress")
        expect(testDraft.currentDrawingData == externalFixtureData(marker: 0x21), "keeps external test draft drawing")

        let vocabularyDrawing = try only(VocabularyHandwritingAttempt.self, in: context)
        expect(vocabularyDrawing.cardID == card.id && vocabularyDrawing.isCorrect, "keeps vocabulary handwriting result")
        expect(vocabularyDrawing.drawingData == externalFixtureData(marker: 0x22), "keeps external vocabulary drawing")

        let importBatch = try only(VocabularyImportBatch.self, in: context)
        expect(importBatch.deckID == deck.id && importBatch.sourceName == "v1-words.csv", "keeps import source")
        expect(importBatch.importedCount == 1 && importBatch.failedCount == 3, "keeps import results")

        let distractor = try only(VocabularyDistractorCache.self, in: context)
        expect(distractor.cardID == card.id && distractor.deckID == deck.id, "keeps distractor cache binding")
        expect(distractor.correctTiles == ["迁", "移"], "keeps correct tiles")
        expect(distractor.distractorTiles == ["升", "级"], "keeps distractor tiles")

        let diary = try only(DiaryEntry.self, in: context)
        expect(diary.learned == "V1 日记内容" && diary.confused == "V1 困惑内容", "keeps diary content")
        expect(diary.items.count == 1, "keeps diary knowledge relationship")

        let knowledge = try only(KnowledgeItem.self, in: context)
        expect(knowledge.summary == "V1 知识点", "keeps knowledge summary")
        expect(knowledge.diaryEntry?.id == diary.id, "keeps inverse diary relationship")
        expect(knowledge.aiEssence == "迁移要保持数据完整", "keeps knowledge analysis")

    }

    private static func verifyRetiredModelsAreAbsentFromV6() {
        let currentModelIDs = Set(PaperClipSchemaV6.models.map(ObjectIdentifier.init))
        let retiredModelIDs = [
            ObjectIdentifier(PaperClipSchemaV1.PDFDocumentItem.self),
            ObjectIdentifier(PaperClipSchemaV1.HandwritingLayer.self),
            ObjectIdentifier(PaperClipSchemaV1.ExamAttempt.self),
            ObjectIdentifier(PaperClipSchemaV1.ExamPageSubmission.self),
            ObjectIdentifier(PaperClipSchemaV1.ExamHandwritingLayer.self),
            ObjectIdentifier(PaperClipSchemaV1.ExamGradeMark.self),
            ObjectIdentifier(PaperClipSchemaV1.VocabularyGeneratedArticle.self),
            ObjectIdentifier(PaperClipSchemaV1.VocabularyArticleRecitationHistory.self),
            ObjectIdentifier(PaperClipSchemaV1.WritingPrompt.self),
            ObjectIdentifier(PaperClipSchemaV1.WritingDraft.self),
            ObjectIdentifier(PaperClipSchemaV1.WritingReview.self),
            ObjectIdentifier(MistakeLibraryItem.self),
            ObjectIdentifier(MistakeAttachment.self),
            ObjectIdentifier(MistakeReviewAttempt.self)
        ]
        expect(
            retiredModelIDs.allSatisfy { !currentModelIDs.contains($0) },
            "V6 excludes every retired entity, including all mistake-library models"
        )
    }

    private static func only<Model: PersistentModel>(
        _ type: Model.Type,
        in context: ModelContext
    ) throws -> Model {
        let models = try context.fetch(FetchDescriptor<Model>())
        expect(models.count == 1, "expected one \(String(describing: type)), got \(models.count)")
        return models[0]
    }

    private static func fixtureUUID(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }

    private static func externalFixtureData(marker: UInt8) -> Data {
        Data(repeating: marker, count: 2 * 1_024 * 1_024)
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError(message, file: file, line: line)
        }
    }
}
