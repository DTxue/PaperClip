import Foundation
import SwiftData

extension PaperClipSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static let models: [any PersistentModel.Type] = [
        PDFDocumentItem.self,
        HandwritingLayer.self,
        ExamAttempt.self,
        ExamPageSubmission.self,
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
}

extension PaperClipSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static let models: [any PersistentModel.Type] = [
        PDFDocumentItem.self,
        HandwritingLayer.self,
        ExamAttempt.self,
        ExamPageSubmission.self,
        ExamHandwritingLayer.self,
        ExamGradeMark.self,
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
        WritingReview.self,
        MistakeLibraryItem.self,
        MistakeAttachment.self,
        MistakeReviewAttempt.self
    ]
}

extension PaperClipSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static let models: [any PersistentModel.Type] = [
        PDFDocumentItem.self,
        HandwritingLayer.self,
        ExamAttempt.self,
        ExamPageSubmission.self,
        ExamHandwritingLayer.self,
        ExamGradeMark.self,
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
        WritingReview.self,
        MistakeLibraryItem.self,
        PaperClipSchemaV2.MistakeAttachment.self,
        PaperClipSchemaV2.MistakeReviewAttempt.self
    ]
}

enum PaperClipMigrationPlan: SchemaMigrationPlan {
    static let schemas: [any VersionedSchema.Type] = [
        PaperClipSchemaV1.self,
        PaperClipSchemaV2.self,
        PaperClipSchemaV3.self
    ]

    static let stages: [MigrationStage] = [
        .custom(
            fromVersion: PaperClipSchemaV1.self,
            toVersion: PaperClipSchemaV2.self,
            willMigrate: { context in
                for layer in try context.fetch(FetchDescriptor<MistakePracticeLayer>()) {
                    context.delete(layer)
                }
                for export in try context.fetch(FetchDescriptor<ExportRecord>()) {
                    context.delete(export)
                }
                for card in try context.fetch(FetchDescriptor<MistakeCard>()) {
                    context.delete(card)
                }
                try context.save()
            },
            didMigrate: nil
        ),
        .lightweight(
            fromVersion: PaperClipSchemaV2.self,
            toVersion: PaperClipSchemaV3.self
        )
    ]
}

enum PaperClipStore {
    static func makeContainer(
        at url: URL? = nil,
        isStoredInMemoryOnly: Bool = false
    ) throws -> ModelContainer {
        precondition(url == nil || !isStoredInMemoryOnly)

        do {
            return try makeCurrentContainer(at: url, isStoredInMemoryOnly: isStoredInMemoryOnly)
        } catch let currentSchemaError {
            guard !isStoredInMemoryOnly else { throw currentSchemaError }

            // Stores created before PaperClip adopted VersionedSchema have no
            // version checksum. Opening once with V1 lets SwiftData perform its
            // inferred migration and stamp the store before the staged V2 move.
            do {
                let legacyContainer = try makeLegacyV1Container(at: url)
                withExtendedLifetime(legacyContainer) {}
            } catch {
                throw currentSchemaError
            }
            return try makeCurrentContainer(at: url, isStoredInMemoryOnly: false)
        }
    }

    private static func makeCurrentContainer(
        at url: URL?,
        isStoredInMemoryOnly: Bool
    ) throws -> ModelContainer {
        let schema = Schema(versionedSchema: PaperClipSchemaV3.self)
        let configuration: ModelConfiguration
        if let url {
            configuration = ModelConfiguration(
                "PaperClip",
                schema: schema,
                url: url
            )
        } else {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: isStoredInMemoryOnly
            )
        }

        return try ModelContainer(
            for: schema,
            migrationPlan: PaperClipMigrationPlan.self,
            configurations: [configuration]
        )
    }

    private static func makeLegacyV1Container(at url: URL?) throws -> ModelContainer {
        let schema = Schema(versionedSchema: PaperClipSchemaV1.self)
        let configuration: ModelConfiguration
        if let url {
            configuration = ModelConfiguration(
                "PaperClip",
                schema: schema,
                url: url
            )
        } else {
            configuration = ModelConfiguration(schema: schema)
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
