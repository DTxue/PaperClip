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

        let newPageSubmissions = try container.mainContext.fetch(FetchDescriptor<ExamPageSubmission>())
        expect(newPageSubmissions.isEmpty, "new page submission model migrates without fabricating records")
        let newMistakes = try container.mainContext.fetch(FetchDescriptor<MistakeLibraryItem>())
        let newAttachments = try container.mainContext.fetch(FetchDescriptor<MistakeAttachment>())
        let newAttempts = try container.mainContext.fetch(FetchDescriptor<MistakeReviewAttempt>())
        expect(
            newMistakes.isEmpty,
            "independent mistake library starts empty"
        )
        expect(
            newAttachments.isEmpty,
            "migration does not retain legacy card images as new attachments"
        )
        expect(
            newAttempts.isEmpty,
            "migration does not retain legacy practice records as new attempts"
        )
        let externalDataDirectory = storeURL.deletingLastPathComponent()
            .appendingPathComponent(".default_SUPPORT", isDirectory: true)
            .appendingPathComponent("_EXTERNAL_DATA", isDirectory: true)
        let remainingExternalFiles = try FileManager.default.contentsOfDirectory(
            at: externalDataDirectory,
            includingPropertiesForKeys: nil
        )
        expect(
            remainingExternalFiles.count == 6,
            "migration removes the legacy practice drawing sidecar"
        )

        try verifyV2ToV3Migration()

        print("PaperClipSchemaMigrationTests: V1 data preserved; legacy mistakes removed; V3 ready")
    }

    private static func verifyV2ToV3Migration() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PaperClipV2ToV3Tests-\(UUID().uuidString)", isDirectory: true)
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
        let migrated = try only(MistakeLibraryItem.self, in: migratedContainer.mainContext)
        expect(migrated.questionText == "V2 物理错题", "V3 keeps V2 mistake text")
        expect(migrated.correctAnswer == "旧答案", "V3 keeps hidden legacy answer data")
        expect(migrated.explanation == "旧解析", "V3 keeps hidden legacy explanation data")
        expect(migrated.grade == Grade.grade7.rawValue, "V3 backfills the default grade")
        expect(migrated.semester == Semester.first.rawValue, "V3 backfills the default semester")
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
        let pdf = try only(PDFDocumentItem.self, in: context)
        expect(pdf.id == fixtureUUID(1), "keeps PDF identity")
        expect(pdf.title == "V1 期中数学", "keeps PDF title")
        expect(pdf.localFileName == "v1-math.pdf", "keeps source PDF file binding")
        expect(pdf.grade == Grade.grade8.rawValue, "keeps PDF classification")

        let handwriting = try only(HandwritingLayer.self, in: context)
        expect(handwriting.documentId == pdf.id, "keeps answer layer document binding")
        expect(handwriting.pageIndex == 2 && handwriting.sessionIndex == 3, "keeps answer layer position")
        expect(handwriting.drawingData == externalFixtureData(marker: 0x11), "keeps external answer drawing data")

        let attempt = try only(ExamAttempt.self, in: context)
        expect(attempt.id == fixtureUUID(2), "keeps exam identity")
        expect(attempt.sourceDocumentId == pdf.id, "keeps exam source binding")
        expect(attempt.sourceDocumentLocalFileName == "v1-math.pdf", "keeps exam source file")
        expect(attempt.selectedPageIndices == [0, 2], "keeps selected exam pages")
        expect(attempt.status == ExamAttemptStatus.submitted.rawValue, "keeps exam status")

        let examDrawing = try only(ExamHandwritingLayer.self, in: context)
        expect(examDrawing.attemptId == attempt.id, "keeps exam drawing attempt binding")
        expect(examDrawing.drawingData == externalFixtureData(marker: 0x12), "keeps external exam drawing data")

        let gradeMark = try only(ExamGradeMark.self, in: context)
        expect(gradeMark.attemptId == attempt.id, "keeps grade mark attempt binding")
        expect(gradeMark.isCorrect && gradeMark.questionNumber == "2", "keeps grade result")
        expect(gradeMark.normalizedAnchor == "0.25,0.75", "keeps grade mark position")

        let folder = try only(VocabularyFolder.self, in: context)
        expect(folder.id == fixtureUUID(5) && folder.title == "V1 词汇文件夹", "keeps vocabulary folder")

        let deck = try only(VocabularyDeck.self, in: context)
        expect(deck.id == fixtureUUID(6) && deck.folderID == folder.id, "keeps vocabulary deck binding")
        expect(deck.dailyNewLimit == 12 && deck.desiredRetention == 0.92, "keeps deck settings")

        let card = try only(VocabularyCard.self, in: context)
        expect(card.id == fixtureUUID(7) && card.deckID == deck.id, "keeps vocabulary card binding")
        expect(card.term == "migration" && card.definition == "迁移", "keeps vocabulary content")
        expect(card.note == "V1 card", "keeps vocabulary note")

        let article = try only(VocabularyGeneratedArticle.self, in: context)
        expect(article.id == fixtureUUID(8) && article.deckID == deck.id, "keeps article binding")
        expect(article.articleText == "Every record survived the migration.", "keeps generated article")

        let recitation = try only(VocabularyArticleRecitationHistory.self, in: context)
        expect(recitation.articleID == article.id, "keeps recitation article binding")
        expect(recitation.stuckSentenceIndexes == [0], "keeps recitation progress")

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

        let prompt = try only(WritingPrompt.self, in: context)
        expect(prompt.id == fixtureUUID(9) && prompt.generatedTitle == "一次平稳升级", "keeps writing prompt")
        expect(prompt.constraints == ["不少于 600 字"], "keeps writing constraints")

        let writingDraft = try only(WritingDraft.self, in: context)
        expect(writingDraft.id == fixtureUUID(10) && writingDraft.promptID == prompt.id, "keeps writing draft binding")
        expect(writingDraft.recognizedText == "升级过程很顺畅。", "keeps recognized writing text")
        expect(writingDraft.drawingData == externalFixtureData(marker: 0x10), "keeps external writing drawing")
        expect(writingDraft.reviewStatus == .graded, "keeps writing review state")

        let writingReview = try only(WritingReview.self, in: context)
        expect(writingReview.promptID == prompt.id && writingReview.draftID == writingDraft.id, "keeps writing review binding")
        expect(writingReview.reviewJSONData == externalFixtureData(marker: 0x25), "keeps external writing review data")
        expect(writingReview.scoreText == "92", "keeps writing score")
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
