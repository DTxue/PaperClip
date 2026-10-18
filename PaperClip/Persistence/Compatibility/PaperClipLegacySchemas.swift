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
        VocabularyFolder.self, VocabularyDeck.self, VocabularyCard.self,
        VocabularyMemoryState.self, VocabularyReviewLog.self, VocabularyStudySession.self,
        VocabularyTestDraft.self, VocabularyHandwritingAttempt.self, VocabularyImportBatch.self,
        VocabularyDistractorCache.self, DiaryEntry.self, KnowledgeItem.self,
        MistakeLibraryItem.self, PaperClipSchemaV2.MistakeAttachment.self,
        PaperClipSchemaV2.MistakeReviewAttempt.self
    ]
}
