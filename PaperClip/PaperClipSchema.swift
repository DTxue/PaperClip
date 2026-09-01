import Foundation
import SwiftData

extension PaperClipSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static let models: [any PersistentModel.Type] = [
        PaperClipSchemaV1.PDFDocumentItem.self,
        PaperClipSchemaV1.HandwritingLayer.self,
        PaperClipSchemaV1.ExamAttempt.self,
        PaperClipSchemaV1.ExamPageSubmission.self,
        PaperClipSchemaV1.ExamHandwritingLayer.self,
        PaperClipSchemaV1.ExamGradeMark.self,
        MistakeCard.self,
        ExportRecord.self,
        MistakePracticeLayer.self,
        VocabularyFolder.self,
        VocabularyDeck.self,
        VocabularyCard.self,
        PaperClipSchemaV1.VocabularyGeneratedArticle.self,
        PaperClipSchemaV1.VocabularyArticleRecitationHistory.self,
        VocabularyMemoryState.self,
        VocabularyReviewLog.self,
        VocabularyStudySession.self,
        VocabularyTestDraft.self,
        VocabularyHandwritingAttempt.self,
        VocabularyImportBatch.self,
        VocabularyDistractorCache.self,
        DiaryEntry.self,
        KnowledgeItem.self,
        PaperClipSchemaV1.WritingPrompt.self,
        PaperClipSchemaV1.WritingDraft.self,
        PaperClipSchemaV1.WritingReview.self
    ]
}

extension PaperClipSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static let models: [any PersistentModel.Type] = [
        PaperClipSchemaV1.PDFDocumentItem.self,
        PaperClipSchemaV1.HandwritingLayer.self,
        PaperClipSchemaV1.ExamAttempt.self,
        PaperClipSchemaV1.ExamPageSubmission.self,
        PaperClipSchemaV1.ExamHandwritingLayer.self,
        PaperClipSchemaV1.ExamGradeMark.self,
        VocabularyFolder.self,
        VocabularyDeck.self,
        VocabularyCard.self,
        PaperClipSchemaV1.VocabularyGeneratedArticle.self,
        PaperClipSchemaV1.VocabularyArticleRecitationHistory.self,
        VocabularyMemoryState.self,
        VocabularyReviewLog.self,
        VocabularyStudySession.self,
        VocabularyTestDraft.self,
        VocabularyHandwritingAttempt.self,
        VocabularyImportBatch.self,
        VocabularyDistractorCache.self,
        DiaryEntry.self,
        KnowledgeItem.self,
        PaperClipSchemaV1.WritingPrompt.self,
        PaperClipSchemaV1.WritingDraft.self,
        PaperClipSchemaV1.WritingReview.self,
        MistakeLibraryItem.self,
        MistakeAttachment.self,
        MistakeReviewAttempt.self
    ]
}

extension PaperClipSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static let models: [any PersistentModel.Type] = [
        PaperClipSchemaV1.PDFDocumentItem.self,
        PaperClipSchemaV1.HandwritingLayer.self,
        PaperClipSchemaV1.ExamAttempt.self,
        PaperClipSchemaV1.ExamPageSubmission.self,
        PaperClipSchemaV1.ExamHandwritingLayer.self,
        PaperClipSchemaV1.ExamGradeMark.self,
        VocabularyFolder.self,
        VocabularyDeck.self,
        VocabularyCard.self,
        PaperClipSchemaV1.VocabularyGeneratedArticle.self,
        PaperClipSchemaV1.VocabularyArticleRecitationHistory.self,
        VocabularyMemoryState.self,
        VocabularyReviewLog.self,
        VocabularyStudySession.self,
        VocabularyTestDraft.self,
        VocabularyHandwritingAttempt.self,
        VocabularyImportBatch.self,
        VocabularyDistractorCache.self,
        DiaryEntry.self,
        KnowledgeItem.self,
        PaperClipSchemaV1.WritingPrompt.self,
        PaperClipSchemaV1.WritingDraft.self,
        PaperClipSchemaV1.WritingReview.self,
        MistakeLibraryItem.self,
        PaperClipSchemaV2.MistakeAttachment.self,
        PaperClipSchemaV2.MistakeReviewAttempt.self
    ]
}

extension PaperClipSchemaV4: VersionedSchema {
    static let versionIdentifier = Schema.Version(4, 0, 0)

    static let models: [any PersistentModel.Type] = [
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
        PaperClipSchemaV1.WritingPrompt.self,
        PaperClipSchemaV1.WritingDraft.self,
        PaperClipSchemaV1.WritingReview.self,
        MistakeLibraryItem.self,
        PaperClipSchemaV2.MistakeAttachment.self,
        PaperClipSchemaV2.MistakeReviewAttempt.self
    ]
}

extension PaperClipSchemaV5: VersionedSchema {
    static let versionIdentifier = Schema.Version(5, 0, 0)

    static let models: [any PersistentModel.Type] = [
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
        MistakeLibraryItem.self,
        PaperClipSchemaV2.MistakeAttachment.self,
        PaperClipSchemaV2.MistakeReviewAttempt.self
    ]
}

enum PaperClipMigrationPlan: SchemaMigrationPlan {
    static let schemas: [any VersionedSchema.Type] = [
        PaperClipSchemaV1.self,
        PaperClipSchemaV2.self,
        PaperClipSchemaV3.self,
        PaperClipSchemaV4.self,
        PaperClipSchemaV5.self
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
        ),
        .custom(
            fromVersion: PaperClipSchemaV3.self,
            toVersion: PaperClipSchemaV4.self,
            willMigrate: { context in
                for model in try context.fetch(FetchDescriptor<PaperClipSchemaV1.ExamGradeMark>()) {
                    context.delete(model)
                }
                for model in try context.fetch(FetchDescriptor<PaperClipSchemaV1.ExamHandwritingLayer>()) {
                    context.delete(model)
                }
                for model in try context.fetch(FetchDescriptor<PaperClipSchemaV1.ExamPageSubmission>()) {
                    context.delete(model)
                }
                for model in try context.fetch(FetchDescriptor<PaperClipSchemaV1.ExamAttempt>()) {
                    context.delete(model)
                }
                for model in try context.fetch(FetchDescriptor<PaperClipSchemaV1.HandwritingLayer>()) {
                    context.delete(model)
                }
                for model in try context.fetch(FetchDescriptor<PaperClipSchemaV1.PDFDocumentItem>()) {
                    context.delete(model)
                }
                for model in try context.fetch(FetchDescriptor<PaperClipSchemaV1.VocabularyArticleRecitationHistory>()) {
                    context.delete(model)
                }
                for model in try context.fetch(FetchDescriptor<PaperClipSchemaV1.VocabularyGeneratedArticle>()) {
                    context.delete(model)
                }
                try context.save()
            },
            didMigrate: nil
        ),
        .custom(
            fromVersion: PaperClipSchemaV4.self,
            toVersion: PaperClipSchemaV5.self,
            willMigrate: { context in
                for model in try context.fetch(FetchDescriptor<PaperClipSchemaV1.WritingReview>()) {
                    context.delete(model)
                }
                for model in try context.fetch(FetchDescriptor<PaperClipSchemaV1.WritingDraft>()) {
                    context.delete(model)
                }
                for model in try context.fetch(FetchDescriptor<PaperClipSchemaV1.WritingPrompt>()) {
                    context.delete(model)
                }
                try context.save()
            },
            didMigrate: nil
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
        let schema = Schema(versionedSchema: PaperClipSchemaV5.self)
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
