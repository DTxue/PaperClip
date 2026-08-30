import Foundation
import SwiftData

/// Regenerates the committed, unversioned V1 store fixture intentionally.
///
/// The migration test never compiles or runs this builder. Keeping fixture
/// generation separate prevents the legacy source schema from drifting with the
/// current application schema during ordinary test runs.
@MainActor
@main
enum PaperClipLegacyStoreFixtureBuilder {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            fatalError("usage: PaperClipLegacyStoreFixtureBuilder <store-url>")
        }

        let storeURL = URL(fileURLWithPath: CommandLine.arguments[1])
        try removeStoreFiles(at: storeURL)

        let schema = Schema(legacyModelTypes)
        let configuration = ModelConfiguration(
            "PaperClipLegacyUnversioned",
            schema: schema,
            url: storeURL
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        let documentID = fixtureUUID(1)
        let attemptID = fixtureUUID(2)
        let mistakeID = fixtureUUID(3)
        let practiceGroupID = fixtureUUID(4)
        let folderID = fixtureUUID(5)
        let deckID = fixtureUUID(6)
        let cardID = fixtureUUID(7)
        let articleID = fixtureUUID(8)
        let promptID = fixtureUUID(9)
        let draftID = fixtureUUID(10)
        let fixtureDate = Date(timeIntervalSince1970: 1_700_000_000)

        context.insert(
            PDFDocumentItem(
                id: documentID,
                title: "V1 期中数学",
                localFileName: "v1-math.pdf",
                fileFingerprint: "v1-pdf-fingerprint",
                grade: Grade.grade8.rawValue,
                semester: Semester.second.rawValue,
                subject: Subject.math.rawValue,
                importDate: fixtureDate,
                lastOpenDate: fixtureDate
            )
        )
        context.insert(
            HandwritingLayer(
                id: fixtureUUID(11),
                documentId: documentID,
                pageIndex: 2,
                drawingData: externalFixtureData(marker: 0x11),
                sessionIndex: 3,
                createdAt: fixtureDate,
                updatedAt: fixtureDate
            )
        )
        context.insert(
            ExamAttempt(
                id: attemptID,
                sourceDocumentId: documentID,
                sourceDocumentTitle: "V1 期中数学",
                sourceDocumentLocalFileName: "v1-math.pdf",
                sourceDocumentFingerprint: "v1-pdf-fingerprint",
                generatedPDFFileName: "v1-attempt.pdf",
                selectedPageIndices: [0, 2],
                status: ExamAttemptStatus.submitted.rawValue,
                createdAt: fixtureDate,
                submittedAt: fixtureDate,
                updatedAt: fixtureDate
            )
        )
        context.insert(
            ExamHandwritingLayer(
                id: fixtureUUID(12),
                sourceDocumentId: documentID,
                attemptId: attemptID,
                pageIndex: 1,
                drawingData: externalFixtureData(marker: 0x12),
                createdAt: fixtureDate,
                updatedAt: fixtureDate
            )
        )
        context.insert(
            ExamGradeMark(
                id: fixtureUUID(13),
                sourceDocumentId: documentID,
                attemptId: attemptID,
                pageIndex: 1,
                isCorrect: true,
                normalizedAnchor: "0.25,0.75",
                confidence: 0.95,
                questionNumber: "2",
                createdAt: fixtureDate,
                updatedAt: fixtureDate
            )
        )
        context.insert(
            MistakeCard(
                id: mistakeID,
                imageFileName: "v1-mistake.jpg",
                originalWidth: 1_200,
                originalHeight: 800,
                grade: Grade.grade8.rawValue,
                semester: Semester.second.rawValue,
                subject: Subject.math.rawValue,
                tagsText: "乘法,易错",
                note: "V1 错题备注",
                recognizedText: "6 × 7 = ?",
                questionType: "填空题",
                correctAnswer: "42",
                sourceDocumentTitle: "V1 期中数学",
                createdAt: fixtureDate,
                updatedAt: fixtureDate
            )
        )
        context.insert(
            ExportRecord(
                id: fixtureUUID(14),
                title: "V1 错题导出",
                cardIDs: [mistakeID],
                layoutType: "compact",
                exportType: "pdf",
                pdfFileName: "v1-export.pdf",
                createdAt: fixtureDate
            )
        )
        context.insert(
            MistakePracticeLayer(
                id: fixtureUUID(15),
                cardID: mistakeID,
                practiceGroupID: practiceGroupID,
                round: 2,
                drawingData: externalFixtureData(marker: 0x15),
                mark: "got_it",
                createdAt: fixtureDate
            )
        )

        context.insert(
            VocabularyFolder(
                id: folderID,
                title: "V1 词汇文件夹",
                createdAt: fixtureDate,
                updatedAt: fixtureDate
            )
        )
        context.insert(
            VocabularyDeck(
                id: deckID,
                folderID: folderID,
                title: "V1 核心词汇",
                dailyNewLimit: 12,
                desiredRetention: 0.92,
                fsrsParametersJSON: "[1,2,3]",
                schedulerVersion: 6,
                createdAt: fixtureDate,
                updatedAt: fixtureDate
            )
        )
        context.insert(
            VocabularyCard(
                id: cardID,
                deckID: deckID,
                term: "migration",
                definition: "迁移",
                englishDefinition: "moving data safely",
                phonetic: "/maɪˈɡreɪʃən/",
                example: "The migration kept every answer.",
                partOfSpeech: "noun",
                tagsText: "upgrade,safety",
                note: "V1 card",
                alternativeAnswersText: "数据迁移",
                createdAt: fixtureDate,
                updatedAt: fixtureDate
            )
        )
        context.insert(
            VocabularyGeneratedArticle(
                id: articleID,
                deckID: deckID,
                title: "V1 Migration Story",
                articleText: "Every record survived the migration.",
                coveredTermsJSON: "[\"migration\"]",
                sourceCardSnapshotHash: "v1-card-hash",
                modelName: "fixture-model",
                promptVersion: 1,
                createdAt: fixtureDate,
                updatedAt: fixtureDate
            )
        )
        context.insert(
            VocabularyArticleRecitationHistory(
                id: fixtureUUID(16),
                deckID: deckID,
                articleID: articleID,
                articleTitle: "V1 Migration Story",
                articleSnapshotHash: "v1-article-hash",
                completedAt: fixtureDate,
                duration: 45,
                sentenceCount: 1,
                wordCount: 6,
                stuckSentenceIndexes: [0],
                createdAt: fixtureDate
            )
        )
        context.insert(
            VocabularyMemoryState(
                id: fixtureUUID(17),
                deckID: deckID,
                cardID: cardID,
                direction: .termToDefinition,
                stage: .review,
                dueDate: fixtureDate,
                lastReviewDate: fixtureDate,
                stability: 4.2,
                difficulty: 3.1,
                retrievability: 0.91,
                scheduledDays: 5,
                learningStep: 2,
                algorithmVersion: 6,
                reviewCount: 7,
                lapseCount: 1
            )
        )
        context.insert(
            VocabularyReviewLog(
                id: fixtureUUID(18),
                cardID: cardID,
                deckID: deckID,
                direction: .termToDefinition,
                rating: .good,
                responseKind: "handwriting",
                duration: 8.5,
                reviewedAt: fixtureDate,
                previousStability: 3.2,
                resultingStability: 4.2,
                previousDifficulty: 3.3,
                resultingDifficulty: 3.1,
                retrievability: 0.91,
                elapsedDays: 4,
                scheduledDays: 5,
                reviewState: VocabularyMemoryStage.review.rawValue,
                algorithmVersion: 6
            )
        )
        let studyItem = VocabularyStudySessionItem(
            id: fixtureUUID(19),
            cardID: cardID,
            prompt: "migration",
            expectedAnswer: "迁移",
            isCorrect: true,
            recognizedText: "迁移",
            comment: "V1 session item"
        )
        context.insert(
            VocabularyStudySession(
                id: fixtureUUID(20),
                deckID: deckID,
                kind: "flashcard",
                startedAt: fixtureDate,
                endedAt: fixtureDate.addingTimeInterval(30),
                duration: 30,
                totalCount: 1,
                correctCount: 1,
                items: [studyItem]
            )
        )
        let draftPayload = VocabularyTestDraftSavePayload(
            batchSize: 5,
            currentBatchIndex: 1,
            currentQuestionIndex: 2,
            currentDrawingData: externalFixtureData(marker: 0x21),
            didFinishAnswering: false,
            startedAt: fixtureDate,
            batches: []
        )
        context.insert(
            VocabularyTestDraft(
                id: fixtureUUID(21),
                deckID: deckID,
                mode: "mixed",
                payload: draftPayload,
                updatedAt: fixtureDate
            )
        )
        context.insert(
            VocabularyHandwritingAttempt(
                id: fixtureUUID(22),
                cardID: cardID,
                deckID: deckID,
                drawingData: externalFixtureData(marker: 0x22),
                isCorrect: true,
                createdAt: fixtureDate
            )
        )
        context.insert(
            VocabularyImportBatch(
                id: fixtureUUID(23),
                deckID: deckID,
                sourceName: "v1-words.csv",
                detectedFormat: "csv",
                importedCount: 1,
                skippedCount: 2,
                failedCount: 3,
                createdAt: fixtureDate
            )
        )
        context.insert(
            VocabularyDistractorCache(
                id: fixtureUUID(24),
                cardID: cardID,
                deckID: deckID,
                correctTiles: ["迁", "移"],
                distractorTiles: ["升", "级"],
                cardTermSnapshot: "migration",
                createdAt: fixtureDate
            )
        )

        let diary = DiaryEntry(date: fixtureDate)
        diary.learned = "V1 日记内容"
        diary.confused = "V1 困惑内容"
        diary.noted = "V1 备忘"
        diary.inspired = "V1 灵感"
        diary.aiState = "done"
        context.insert(diary)
        let knowledge = KnowledgeItem(summary: "V1 知识点", source: "learned", entry: diary)
        knowledge.subject = Subject.math.rawValue
        knowledge.status = "confirmed"
        knowledge.aiEssence = "迁移要保持数据完整"
        knowledge.aiAnalysisState = "done"
        diary.items.append(knowledge)
        context.insert(knowledge)

        context.insert(
            WritingPrompt(
                id: promptID,
                language: .chinese,
                studentGrade: "八年级",
                requirementInput: "记录一次安全升级",
                generatedTitle: "一次平稳升级",
                generatedRequirement: "写清操作过程与感受",
                constraints: ["不少于 600 字"],
                rubric: ["流程清晰"],
                createdAt: fixtureDate,
                updatedAt: fixtureDate
            )
        )
        context.insert(
            WritingDraft(
                id: draftID,
                promptID: promptID,
                language: .chinese,
                paperStyle: .grid,
                blackPaperMode: true,
                drawingData: externalFixtureData(marker: 0x10),
                recognizedText: "升级过程很顺畅。",
                reviewStatus: .graded,
                createdAt: fixtureDate,
                updatedAt: fixtureDate
            )
        )
        context.insert(
            WritingReview(
                id: fixtureUUID(25),
                promptID: promptID,
                draftID: draftID,
                language: .chinese,
                recognizedText: "升级过程很顺畅。",
                reviewJSONData: externalFixtureData(marker: 0x25),
                overallJudgement: "结构完整",
                teacherComment: "继续保持",
                scoreText: "92",
                createdAt: fixtureDate
            )
        )

        try context.save()
        print("Legacy V1 fixture written to \(storeURL.path)")
    }

    private static func fixtureUUID(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }

    private static func externalFixtureData(marker: UInt8) -> Data {
        Data(repeating: marker, count: 2 * 1_024 * 1_024)
    }

    private static let legacyModelTypes: [any PersistentModel.Type] = [
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
        VocabularyGeneratedArticle.self,
        VocabularyArticleRecitationHistory.self,
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
    ]

    private static func removeStoreFiles(at url: URL) throws {
        let fileManager = FileManager.default
        for suffix in ["", "-shm", "-wal"] {
            let candidate = URL(fileURLWithPath: url.path + suffix)
            if fileManager.fileExists(atPath: candidate.path) {
                try fileManager.removeItem(at: candidate)
            }
        }
    }
}
