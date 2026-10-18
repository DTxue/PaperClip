import SwiftData

enum PaperClipMigrationPlan: SchemaMigrationPlan {
    static let schemas: [any VersionedSchema.Type] = [
        PaperClipSchemaV1.self,
        PaperClipSchemaV2.self,
        PaperClipSchemaV3.self,
        PaperClipSchemaV4.self,
        PaperClipSchemaV5.self,
        PaperClipSchemaV6.self
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
        ),
        .custom(
            fromVersion: PaperClipSchemaV5.self,
            toVersion: PaperClipSchemaV6.self,
            willMigrate: { context in
                for model in try context.fetch(FetchDescriptor<MistakeReviewAttempt>()) {
                    context.delete(model)
                }
                for model in try context.fetch(FetchDescriptor<MistakeAttachment>()) {
                    context.delete(model)
                }
                for model in try context.fetch(FetchDescriptor<MistakeLibraryItem>()) {
                    context.delete(model)
                }
                try context.save()
            },
            didMigrate: nil
        )
    ]
}
