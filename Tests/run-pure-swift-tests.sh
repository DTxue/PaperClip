#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${TMPDIR:-/tmp}/paperclip-pure-swift-tests"

mkdir -p "$BUILD_DIR"
cd "$ROOT_DIR"

run_swift_test() {
    local name="$1"
    shift

    echo "==> $name"
    swiftc "$@" -o "$BUILD_DIR/$name"
    "$BUILD_DIR/$name"
}

run_swift_test AIServiceModelsTests \
    PaperClip/AIResponseJSONValueExtractor.swift \
    PaperClip/AIResponseJSONSanitizer.swift \
    PaperClip/AIDecodingSupport.swift \
    PaperClip/AIServiceModels.swift \
    PaperClip/AIQuestionModels.swift \
    PaperClip/AIExamGradingModels.swift \
    PaperClip/AIVocabularyModels.swift \
    PaperClip/AIWritingPromptModels.swift \
    PaperClip/AIWritingRecognitionModels.swift \
    PaperClip/AIWritingModels.swift \
    PaperClip/WritingReviewJSONStorage.swift \
    PaperClip/AIWritingReviewDisplayText.swift \
    PaperClip/AIWritingReviewScoreModels.swift \
    PaperClip/AIWritingReviewContentAdviceModels.swift \
    PaperClip/AIWritingReviewLanguageAdviceModels.swift \
    PaperClip/AIWritingReviewGoodWordsModels.swift \
    PaperClip/AIWritingReviewLanguageModels.swift \
    PaperClip/AIWritingReviewBlueprintModels.swift \
    PaperClip/AIWritingReviewAdvancedModels.swift \
    PaperClip/AIWritingReviewCoreSceneModels.swift \
    PaperClip/AIWritingReviewReconstructionModels.swift \
    Tests/AIServiceModelsTests.swift

run_swift_test AIModelRoutingTests \
    PaperClip/AIServiceError.swift \
    PaperClip/AIServiceModels.swift \
    PaperClip/AIModelRouting.swift \
    Tests/AIModelRoutingTests.swift

run_swift_test VocabularyAIPromptsTests \
    PaperClip/AIResponseJSONValueExtractor.swift \
    PaperClip/AIResponseJSONSanitizer.swift \
    PaperClip/AIDecodingSupport.swift \
    PaperClip/AIVocabularyModels.swift \
    PaperClip/VocabularyArticleRecitation.swift \
    PaperClip/VocabularyArticleModePolicy.swift \
    PaperClip/VocabularyAIPrompts.swift \
    Tests/VocabularyAIPromptsTests.swift

run_swift_test VocabularyArticleRecitationTests \
    PaperClip/VocabularyArticleRecitation.swift \
    Tests/VocabularyArticleRecitationTests.swift

run_swift_test VocabularyArticleModePolicyTests \
    PaperClip/VocabularyArticleRecitation.swift \
    PaperClip/VocabularyArticleModePolicy.swift \
    Tests/VocabularyArticleModePolicyTests.swift

run_swift_test AIServiceErrorMessageSupportTests \
    PaperClip/AIServiceError.swift \
    PaperClip/AIServicePayloads.swift \
    PaperClip/AIServiceErrorPayloads.swift \
    PaperClip/AIServiceErrorMessageSupport.swift \
    PaperClip/AIServiceRequestRunner.swift \
    Tests/AIServiceErrorMessageSupportTests.swift

run_swift_test AIServiceResponseDecodingTests \
    PaperClip/AIResponseJSONValueExtractor.swift \
    PaperClip/AIResponseJSONSanitizer.swift \
    PaperClip/AIDecodingSupport.swift \
    PaperClip/AIVocabularyModels.swift \
    Tests/AIServiceResponseDecodingTests.swift

run_swift_test ImageJPEGProfileTests \
    PaperClip/ImageJPEGProfile.swift \
    Tests/ImageJPEGProfileTests.swift

run_swift_test ImageEncodingPlanTests \
    PaperClip/ImageJPEGProfile.swift \
    PaperClip/ImageEncodingPlan.swift \
    Tests/ImageEncodingPlanTests.swift

run_swift_test LocalImageCacheKeyTests \
    PaperClip/NormalizedCropString.swift \
    PaperClip/LocalImageCacheKey.swift \
    Tests/LocalImageCacheKeyTests.swift

run_swift_test StoredFileTests \
    PaperClip/AppStorageDirectory.swift \
    PaperClip/StoredFile.swift \
    Tests/StoredFileTests.swift

run_swift_test CanvasSizeReportSupportTests \
    PaperClip/CanvasSizeReportSupport.swift \
    Tests/CanvasSizeReportSupportTests.swift

run_swift_test DrawingDataSupportTests \
    PaperClip/DrawingDataSupport.swift \
    Tests/DrawingDataSupportTests.swift

run_swift_test HomeKnowledgeSnapshotTests \
    PaperClip/AppStorageDirectory.swift \
    PaperClip/AcademicTaxonomy.swift \
    PaperClip/ModelContextHelpers.swift \
    PaperClip/DiaryEntryContentPresence.swift \
    PaperClip/DiaryModels.swift \
    PaperClip/HomeKnowledgeModels.swift \
    Tests/HomeKnowledgeSnapshotTests.swift

run_swift_test HomeDiarySelectionDecisionTests \
    PaperClip/HomeDiarySelectionDecision.swift \
    Tests/HomeDiarySelectionDecisionTests.swift

run_swift_test DiaryCalendarSupportTests \
    PaperClip/AppStorageDirectory.swift \
    PaperClip/ModelContextHelpers.swift \
    PaperClip/DiaryEntryContentPresence.swift \
    PaperClip/DiaryModels.swift \
    PaperClip/DiaryCalendarSupport.swift \
    Tests/DiaryCalendarSupportTests.swift

run_swift_test DiaryKnowledgeSnapshotTests \
    PaperClip/AppStorageDirectory.swift \
    PaperClip/AIKnowledgeModels.swift \
    PaperClip/ModelContextHelpers.swift \
    PaperClip/DiaryEntryContentPresence.swift \
    PaperClip/DiaryModels.swift \
    PaperClip/KnowledgeItemAnalysisSupport.swift \
    PaperClip/DiaryKnowledgeSnapshot.swift \
    Tests/DiaryKnowledgeSnapshotTests.swift

run_swift_test DiaryHistoryRowDataTests \
    PaperClip/AppStorageDirectory.swift \
    PaperClip/AIKnowledgeModels.swift \
    PaperClip/ModelContextHelpers.swift \
    PaperClip/DiaryEntryContentPresence.swift \
    PaperClip/DiaryModels.swift \
    PaperClip/KnowledgeItemAnalysisSupport.swift \
    PaperClip/ViewTaskSlot.swift \
    PaperClip/DiaryViewModels.swift \
    PaperClip/DiaryHistoryRowData.swift \
    Tests/DiaryHistoryRowDataTests.swift

run_swift_test MasteryStatusSummaryTests \
    PaperClip/AppStorageDirectory.swift \
    PaperClip/StoredFile.swift \
    PaperClip/AcademicTaxonomy.swift \
    PaperClip/MistakeClassification.swift \
    PaperClip/QuestionType.swift \
    PaperClip/MistakeTagModels.swift \
    PaperClip/MistakeModels.swift \
    PaperClip/MasteryStatusSegment.swift \
    PaperClip/MasteryStatusSummary.swift \
    Tests/MasteryStatusSummaryTests.swift

run_swift_test ExamAttemptStatusTests \
    PaperClip/MistakeClassification.swift \
    Tests/ExamAttemptStatusTests.swift

run_swift_test PDFExamGradingSupportTests \
    PaperClip/PDFExamGradingSupport.swift \
    Tests/PDFExamGradingSupportTests.swift

run_swift_test PDFExamGradingTransactionTests \
    PaperClip/AppStorageDirectory.swift \
    PaperClip/StoredFile.swift \
    PaperClip/AcademicTaxonomy.swift \
    PaperClip/MistakeClassification.swift \
    PaperClip/QuestionType.swift \
    PaperClip/PDFPageIndexDisplay.swift \
    PaperClip/PDFPageSelectionSet.swift \
    PaperClip/PDFPageExportSelectionSupport.swift \
    PaperClip/PDFDocumentModels.swift \
    PaperClip/HandwritingLayerModel.swift \
    PaperClip/ExamModels.swift \
    PaperClip/ExamHandwritingLayerModel.swift \
    PaperClip/ExamGradeMarkModel.swift \
    PaperClip/ModelContextHelpers.swift \
    PaperClip/AIResponseJSONValueExtractor.swift \
    PaperClip/AIResponseJSONSanitizer.swift \
    PaperClip/AIDecodingSupport.swift \
    PaperClip/AIExamGradingModels.swift \
    PaperClip/PDFExamGradingSupport.swift \
    PaperClip/PDFExamGradingTransaction.swift \
    Tests/PDFExamGradingTransactionTests.swift

run_swift_test KnowledgePointVocabularyTests \
    PaperClip/AcademicTaxonomy.swift \
    PaperClip/KnowledgePointVocabulary.swift \
    PaperClip/KnowledgePointVocabularySeed.swift \
    PaperClip/KnowledgePointVocabularyMathSeed.swift \
    PaperClip/KnowledgePointVocabularyScienceSeed.swift \
    Tests/KnowledgePointVocabularyTests.swift

run_swift_test KnowledgeAIPromptsTests \
    PaperClip/AIKnowledgeModels.swift \
    PaperClip/KnowledgeAnalysisDecodable.swift \
    PaperClip/KnowledgeAIAnalysisSubjectStrategies.swift \
    PaperClip/KnowledgeAIAnalysisOutputSchema.swift \
    PaperClip/KnowledgeAIPrompts.swift \
    Tests/KnowledgeAIPromptsTests.swift

run_swift_test MathematicsReferenceTests \
    PaperClip/MathematicsReferenceModels.swift \
    PaperClip/MathematicsReferenceCatalogLoader.swift \
    PaperClip/MathematicsReference.swift \
    Tests/MathematicsReferenceTests.swift

run_swift_test MistakeListSnapshotTests \
    PaperClip/AppStorageDirectory.swift \
    PaperClip/StoredFile.swift \
    PaperClip/AcademicTaxonomy.swift \
    PaperClip/MasteryStatusSegment.swift \
    PaperClip/MasteryStatusSummary.swift \
    PaperClip/MistakeClassification.swift \
    PaperClip/QuestionType.swift \
    PaperClip/MistakeTagModels.swift \
    PaperClip/MistakeModels.swift \
    PaperClip/MistakePracticeModels.swift \
    PaperClip/MistakeCardViewModels.swift \
    PaperClip/MistakeCardRowProjection.swift \
    PaperClip/MistakeCardFilterQuery.swift \
    PaperClip/MistakeCardRowDisplay.swift \
    PaperClip/MistakeListSnapshot.swift \
    PaperClip/MistakePaperSelectionModels.swift \
    PaperClip/RelatedMistakeModels.swift \
    Tests/MistakeListSnapshotTests.swift

run_swift_test MistakePersistenceTests \
    PaperClip/AppStorageDirectory.swift \
    PaperClip/StoredFile.swift \
    PaperClip/AcademicTaxonomy.swift \
    PaperClip/MasteryStatusSegment.swift \
    PaperClip/MasteryStatusSummary.swift \
    PaperClip/MistakeClassification.swift \
    PaperClip/QuestionType.swift \
    PaperClip/MistakeTagModels.swift \
    PaperClip/MistakeModels.swift \
    PaperClip/MistakePracticeModels.swift \
    PaperClip/ModelContextHelpers.swift \
    PaperClip/MistakePersistence.swift \
    PaperClip/MistakePracticePersistence.swift \
    PaperClip/PaperResultMasterySync.swift \
    Tests/MistakePersistenceTests.swift

run_swift_test MistakeRecognitionQueueTests \
    PaperClip/MistakeRecognitionQueue.swift \
    Tests/MistakeRecognitionQueueTests.swift

run_swift_test MistakeRecognitionStatusSupportTests \
    PaperClip/MistakeClassification.swift \
    PaperClip/MistakeRecognitionStatusSupport.swift \
    Tests/MistakeRecognitionStatusSupportTests.swift

run_swift_test MistakeSelectionCaptureSupportTests \
    PaperClip/MistakeSelectionCaptureSupport.swift \
    Tests/MistakeSelectionCaptureSupportTests.swift

run_swift_test PDFExamHistorySnapshotTests \
    PaperClip/AppStorageDirectory.swift \
    PaperClip/StoredFile.swift \
    PaperClip/MistakeClassification.swift \
    PaperClip/QuestionType.swift \
    PaperClip/PDFPageIndexDisplay.swift \
    PaperClip/PDFPageSelectionSet.swift \
    PaperClip/PDFPageExportSelectionSupport.swift \
    PaperClip/ExamModels.swift \
    PaperClip/ExamHandwritingLayerModel.swift \
    PaperClip/ExamGradeMarkModel.swift \
    PaperClip/PDFExamHistoryStatusStyle.swift \
    PaperClip/PDFExamHistoryViews.swift \
    Tests/PDFExamHistorySnapshotTests.swift

run_swift_test PDFPageRenderGeometryTests \
    PaperClip/PDFPageRenderGeometry.swift \
    Tests/PDFPageRenderGeometryTests.swift

run_swift_test PDFPageExportSelectionSupportTests \
    PaperClip/PDFPageIndexDisplay.swift \
    PaperClip/PDFPageSelectionSet.swift \
    PaperClip/PDFPageExportSelectionSupport.swift \
    PaperClip/PDFPageExportRenderInput.swift \
    PaperClip/PDFPageExportRequest.swift \
    Tests/PDFPageExportSelectionSupportTests.swift

run_swift_test PDFGradeStampIndexTests \
    PaperClip/PDFGradeStampModels.swift \
    Tests/PDFGradeStampIndexTests.swift

run_swift_test PDFCanvasUpdateStateTests \
    PaperClip/PDFGradeStampModels.swift \
    PaperClip/PDFCanvasUpdateState.swift \
    Tests/PDFCanvasUpdateStateTests.swift

run_swift_test PDFLongImageLayoutSupportTests \
    PaperClip/PDFLongImageLayoutSupport.swift \
    PaperClip/PDFLongImageStackLayoutSupport.swift \
    Tests/PDFLongImageLayoutSupportTests.swift

run_swift_test PDFCropGeometryTests \
    PaperClip/PDFPageRenderGeometry.swift \
    PaperClip/PDFCropGeometry.swift \
    Tests/PDFCropGeometryTests.swift

run_swift_test HandwritingRenderGeometryTests \
    PaperClip/HandwritingRenderGeometry.swift \
    Tests/HandwritingRenderGeometryTests.swift

run_swift_test PDFSelectionGeometryTests \
    PaperClip/PDFSelectionModels.swift \
    PaperClip/RectGeometry.swift \
    PaperClip/PDFSelectionHandleGeometry.swift \
    PaperClip/PDFSelectionGeometry.swift \
    Tests/PDFSelectionGeometryTests.swift

run_swift_test PDFToolPickerVisibilitySupportTests \
    PaperClip/PDFToolPickerVisibilitySupport.swift \
    Tests/PDFToolPickerVisibilitySupportTests.swift

run_swift_test QuestionCropGeometryTests \
    PaperClip/NormalizedCropString.swift \
    PaperClip/QuestionCropGeometry.swift \
    PaperClip/QuestionCropRectOperations.swift \
    Tests/QuestionCropGeometryTests.swift

run_swift_test PaperObjectiveAnswerSelectionTests \
    PaperClip/PaperObjectiveAnswerSelection.swift \
    Tests/PaperObjectiveAnswerSelectionTests.swift

run_swift_test PaperChoiceParserTests \
    PaperClip/QuestionType.swift \
    PaperClip/PaperChoiceParser.swift \
    Tests/PaperChoiceParserTests.swift

run_swift_test PDFWorkspaceCoreTests \
    PaperClip/AppStorageDirectory.swift \
    PaperClip/StoredFile.swift \
    PaperClip/AcademicTaxonomy.swift \
    PaperClip/PDFDocumentModels.swift \
    PaperClip/PDFDocumentEditDraft.swift \
    PaperClip/PDFWorkspaceCore.swift \
    Tests/PDFWorkspaceCoreTests.swift

run_swift_test PDFPersistenceTests \
    PaperClip/AppStorageDirectory.swift \
    PaperClip/StoredFile.swift \
    PaperClip/AcademicTaxonomy.swift \
    PaperClip/MistakeClassification.swift \
    PaperClip/QuestionType.swift \
    PaperClip/PDFPageIndexDisplay.swift \
    PaperClip/PDFPageSelectionSet.swift \
    PaperClip/PDFPageExportSelectionSupport.swift \
    PaperClip/PDFDocumentModels.swift \
    PaperClip/HandwritingLayerModel.swift \
    PaperClip/ExamModels.swift \
    PaperClip/ExamHandwritingLayerModel.swift \
    PaperClip/ExamGradeMarkModel.swift \
    PaperClip/ModelContextHelpers.swift \
    PaperClip/PDFPersistence.swift \
    PaperClip/PDFWorkspaceCore.swift \
    PaperClip/PDFAnswerLayerStore.swift \
    PaperClip/PDFDocumentCascadeDeletion.swift \
    Tests/PDFPersistenceTests.swift

run_swift_test PreferredSubjectsTests \
    PaperClip/AcademicTaxonomy.swift \
    PaperClip/PreferredSubjects.swift \
    Tests/PreferredSubjectsTests.swift

run_swift_test MistakeCardEditorDraftLogicTests \
    PaperClip/AcademicTaxonomy.swift \
    PaperClip/PreferredSubjects.swift \
    PaperClip/MistakeTagModels.swift \
    PaperClip/MistakeCardEditorDraftLogic.swift \
    Tests/MistakeCardEditorDraftLogicTests.swift

run_swift_test VocabularyHomeSnapshotTests \
    PaperClip/VocabularyModels.swift \
    PaperClip/VocabularyCardDerivedProperties.swift \
    PaperClip/VocabularyCoreEnums.swift \
    PaperClip/VocabularyMemoryModels.swift \
    PaperClip/VocabularyReviewRating.swift \
    PaperClip/VocabularyReviewModels.swift \
    PaperClip/VocabularyMemoryIndexes.swift \
    PaperClip/VocabularyHomeSnapshotInputs.swift \
    PaperClip/VocabularyHomeSnapshot.swift \
    Tests/VocabularyHomeSnapshotTests.swift

run_swift_test VocabularyDeckSnapshotTests \
    PaperClip/VocabularyModels.swift \
    PaperClip/VocabularyCardDerivedProperties.swift \
    PaperClip/VocabularyCoreEnums.swift \
    PaperClip/VocabularyMemoryModels.swift \
    PaperClip/VocabularyReviewRating.swift \
    PaperClip/VocabularyReviewModels.swift \
    PaperClip/VocabularyMemoryIndexes.swift \
    PaperClip/VocabularyCardRowData.swift \
    PaperClip/VocabularyDeckSnapshot.swift \
    Tests/VocabularyDeckSnapshotTests.swift

run_swift_test VocabularyCardEditorModelsTests \
    PaperClip/VocabularyModels.swift \
    PaperClip/VocabularyCardDerivedProperties.swift \
    PaperClip/VocabularyCardEditorModels.swift \
    Tests/VocabularyCardEditorModelsTests.swift

run_swift_test VocabularyAnswerCheckerTests \
    PaperClip/VocabularyModels.swift \
    PaperClip/VocabularyCardDerivedProperties.swift \
    PaperClip/VocabularyCoreEnums.swift \
    PaperClip/VocabularyAnswerChecker.swift \
    Tests/VocabularyAnswerCheckerTests.swift

run_swift_test VocabularyDistractorReplacementTests \
    PaperClip/VocabularyDistractorReplacementSupport.swift \
    Tests/VocabularyDistractorReplacementTests.swift

run_swift_test VocabularyReviewRatingTests \
    PaperClip/VocabularyModels.swift \
    PaperClip/VocabularyCardDerivedProperties.swift \
    PaperClip/VocabularyCoreEnums.swift \
    PaperClip/VocabularyReviewRating.swift \
    PaperClip/VocabularyReviewModels.swift \
    PaperClip/VocabularyFlashcardSwipeDecision.swift \
    Tests/VocabularyReviewRatingTests.swift

run_swift_test VocabularyReviewFuzzFactorTests \
    PaperClip/VocabularyModels.swift \
    PaperClip/VocabularyCardDerivedProperties.swift \
    PaperClip/VocabularyCoreEnums.swift \
    PaperClip/VocabularyReviewFuzzFactor.swift \
    Tests/VocabularyReviewFuzzFactorTests.swift

run_swift_test VocabularySchedulingCoreTests \
    PaperClip/VocabularyScheduleModels.swift \
    PaperClip/VocabularySchedulingCore.swift \
    PaperClip/VocabularyScheduleStageNormalization.swift \
    PaperClip/VocabularyLearningStagePlan.swift \
    PaperClip/VocabularySchedulingMath.swift \
    PaperClip/VocabularySchedulingFormula.swift \
    PaperClip/VocabularySchedulingIntervals.swift \
    PaperClip/VocabularySchedulingLearningIntervals.swift \
    PaperClip/VocabularySchedulingTransitions.swift \
    PaperClip/VocabularySchedulingReviewTransitions.swift \
    Tests/VocabularySchedulingCoreTests.swift

run_swift_test VocabularyStudyQueueBuilderTests \
    PaperClip/VocabularyModels.swift \
    PaperClip/VocabularyCardDerivedProperties.swift \
    PaperClip/VocabularyCoreEnums.swift \
    PaperClip/VocabularyMemoryModels.swift \
    PaperClip/VocabularyReviewRating.swift \
    PaperClip/VocabularyReviewModels.swift \
    PaperClip/VocabularyScheduleModels.swift \
    PaperClip/VocabularySchedulingCore.swift \
    PaperClip/VocabularyScheduleStageNormalization.swift \
    PaperClip/VocabularyLearningStagePlan.swift \
    PaperClip/VocabularySchedulingMath.swift \
    PaperClip/VocabularySchedulingFormula.swift \
    PaperClip/VocabularySchedulingIntervals.swift \
    PaperClip/VocabularySchedulingLearningIntervals.swift \
    PaperClip/VocabularySchedulingTransitions.swift \
    PaperClip/VocabularySchedulingReviewTransitions.swift \
    PaperClip/VocabularyJSONStorage.swift \
    PaperClip/VocabularyMemoryRetrievability.swift \
    PaperClip/VocabularyStudyQueueRanking.swift \
    PaperClip/VocabularyStudyQueuePlan.swift \
    PaperClip/VocabularyStudyQueueBuilder.swift \
    Tests/VocabularyStudyQueueBuilderTests.swift

run_swift_test VocabularyWordBankBuilderTests \
    PaperClip/VocabularyModels.swift \
    PaperClip/VocabularyWordBankTile.swift \
    PaperClip/VocabularyWordBankBuilder.swift \
    Tests/VocabularyWordBankBuilderTests.swift

run_swift_test VocabularyTestQuestionCountTests \
    PaperClip/VocabularyTestQuestionCount.swift \
    Tests/VocabularyTestQuestionCountTests.swift

run_swift_test VocabularyGradingPolicyTests \
    PaperClip/AIResponseJSONValueExtractor.swift \
    PaperClip/AIResponseJSONSanitizer.swift \
    PaperClip/AIDecodingSupport.swift \
    PaperClip/AIVocabularyModels.swift \
    PaperClip/VocabularyGradingPolicy.swift \
    Tests/VocabularyGradingPolicyTests.swift

run_swift_test VocabularyTestQuestionSelectorTests \
    PaperClip/VocabularyModels.swift \
    PaperClip/VocabularyCardDerivedProperties.swift \
    PaperClip/VocabularyCoreEnums.swift \
    PaperClip/VocabularyMemoryModels.swift \
    PaperClip/VocabularyReviewRating.swift \
    PaperClip/VocabularyReviewModels.swift \
    PaperClip/VocabularyScheduleModels.swift \
    PaperClip/VocabularySchedulingCore.swift \
    PaperClip/VocabularyScheduleStageNormalization.swift \
    PaperClip/VocabularyLearningStagePlan.swift \
    PaperClip/VocabularySchedulingMath.swift \
    PaperClip/VocabularySchedulingFormula.swift \
    PaperClip/VocabularySchedulingIntervals.swift \
    PaperClip/VocabularySchedulingLearningIntervals.swift \
    PaperClip/VocabularySchedulingTransitions.swift \
    PaperClip/VocabularySchedulingReviewTransitions.swift \
    PaperClip/VocabularyJSONStorage.swift \
    PaperClip/VocabularyMemoryRetrievability.swift \
    PaperClip/VocabularyMemoryScheduler.swift \
    PaperClip/VocabularyMemorySchedulerCalculations.swift \
    PaperClip/VocabularyAnsweringActionTitle.swift \
    PaperClip/VocabularyTestQuestionPriority.swift \
    PaperClip/VocabularyTestQuestionSelector.swift \
    Tests/VocabularyTestQuestionSelectorTests.swift

run_swift_test VocabularyWeightedMasteryTests \
    PaperClip/VocabularyModels.swift \
    PaperClip/VocabularyCardDerivedProperties.swift \
    PaperClip/VocabularyCoreEnums.swift \
    PaperClip/VocabularyReviewRating.swift \
    PaperClip/VocabularyReviewModels.swift \
    PaperClip/VocabularyWeightedMastery.swift \
    Tests/VocabularyWeightedMasteryTests.swift

run_swift_test VocabularyStudySessionMetricsTests \
    PaperClip/VocabularyStudySessionMetrics.swift \
    Tests/VocabularyStudySessionMetricsTests.swift

run_swift_test VocabularyStudySessionDraftTests \
    PaperClip/VocabularyJSONStorage.swift \
    PaperClip/VocabularyStudySessionMetrics.swift \
    PaperClip/VocabularyStudySessionItem.swift \
    PaperClip/VocabularyStudyModels.swift \
    PaperClip/VocabularyStudySessionDraft.swift \
    Tests/VocabularyStudySessionDraftTests.swift

run_swift_test VocabularyStudySessionSnapshotsTests \
    PaperClip/VocabularyJSONStorage.swift \
    PaperClip/VocabularyStudySessionMetrics.swift \
    PaperClip/VocabularyStudySessionItem.swift \
    PaperClip/VocabularyStudyModels.swift \
    PaperClip/VocabularyStudySessionSnapshots.swift \
    PaperClip/VocabularyStudySessionFormat.swift \
    Tests/VocabularyStudySessionSnapshotsTests.swift

run_swift_test VocabularyFlashcardReviewItemFactoryTests \
    PaperClip/VocabularyModels.swift \
    PaperClip/VocabularyCardDerivedProperties.swift \
    PaperClip/VocabularyCoreEnums.swift \
    PaperClip/VocabularyReviewRating.swift \
    PaperClip/VocabularyReviewModels.swift \
    PaperClip/VocabularyJSONStorage.swift \
    PaperClip/VocabularyStudySessionMetrics.swift \
    PaperClip/VocabularyStudySessionItem.swift \
    PaperClip/VocabularyStudyModels.swift \
    PaperClip/VocabularyStudySessionDraft.swift \
    PaperClip/VocabularyFlashcardReviewItemFactory.swift \
    Tests/VocabularyFlashcardReviewItemFactoryTests.swift

run_swift_test VocabularyPersistenceTests \
    PaperClip/AIResponseJSONValueExtractor.swift \
    PaperClip/AIResponseJSONSanitizer.swift \
    PaperClip/AIDecodingSupport.swift \
    PaperClip/AIVocabularyModels.swift \
    PaperClip/ModelContextHelpers.swift \
    PaperClip/VocabularyArticleRecitation.swift \
    PaperClip/VocabularyModels.swift \
    PaperClip/VocabularyCardDerivedProperties.swift \
    PaperClip/VocabularyCoreEnums.swift \
    PaperClip/VocabularyMemoryModels.swift \
    PaperClip/VocabularyReviewRating.swift \
    PaperClip/VocabularyReviewModels.swift \
    PaperClip/VocabularyTextFormat.swift \
    PaperClip/VocabularyImportRow.swift \
    PaperClip/VocabularyImportProjection.swift \
    PaperClip/VocabularyTextImportModels.swift \
    PaperClip/VocabularyImportOptions.swift \
    PaperClip/VocabularyAnswerChecker.swift \
    PaperClip/VocabularyJSONStorage.swift \
    PaperClip/VocabularyPersistenceSupport.swift \
    PaperClip/VocabularyPersistence.swift \
    PaperClip/VocabularyStudyPersistence.swift \
    PaperClip/VocabularyMemoryPersistence.swift \
    PaperClip/VocabularyStudySessionMetrics.swift \
    PaperClip/VocabularyStudySessionItem.swift \
    PaperClip/VocabularyStudyModels.swift \
    PaperClip/VocabularyStudySessionDraft.swift \
    PaperClip/VocabularyTestPersistenceModels.swift \
    PaperClip/VocabularyHandwritingAttempt.swift \
    PaperClip/VocabularyDistractorCache.swift \
    PaperClip/VocabularyImportModels.swift \
    PaperClip/VocabularyImportCardWriter.swift \
    PaperClip/VocabularyImportOperations.swift \
    PaperClip/VocabularyDistractorReplacementSupport.swift \
    PaperClip/VocabularyDistractorPersistence.swift \
    PaperClip/VocabularyCascadeDeletion.swift \
    PaperClip/VocabularyMemoryIndexes.swift \
    PaperClip/VocabularyCardRowData.swift \
    PaperClip/VocabularyViewModels.swift \
    Tests/VocabularyPersistenceTests.swift

run_swift_test VocabularyTextImporterTests \
    PaperClip/VocabularyTextFormat.swift \
    PaperClip/VocabularyImportRow.swift \
    PaperClip/VocabularyImportProjection.swift \
    PaperClip/VocabularyTextImportModels.swift \
    PaperClip/VocabularyTextFileLoader.swift \
    PaperClip/VocabularyTextImporter.swift \
    PaperClip/VocabularyTextFormatDetector.swift \
    PaperClip/VocabularyTextParserSupport.swift \
    PaperClip/VocabularyDelimitedTextParser.swift \
    PaperClip/VocabularyPairedLineTextParser.swift \
    PaperClip/VocabularyJSONTextParser.swift \
    PaperClip/VocabularyTextRowBuilder.swift \
    PaperClip/StringRegexSplitting.swift \
    Tests/VocabularyTextImporterTests.swift

run_swift_test WritingHomeSnapshotTests \
    PaperClip/WritingLanguageModels.swift \
    PaperClip/WritingPaperModels.swift \
    PaperClip/WritingPromptGenerationDraft.swift \
    PaperClip/WritingPromptModel.swift \
    PaperClip/WritingDraftModel.swift \
    PaperClip/WritingReviewModel.swift \
    PaperClip/WritingHomeModels.swift \
    PaperClip/WritingHomeSnapshot.swift \
    PaperClip/WritingPromptDeletionSelection.swift \
    Tests/WritingHomeSnapshotTests.swift

run_swift_test WritingDraftPersistenceSupportTests \
    PaperClip/WritingLanguageModels.swift \
    PaperClip/WritingPaperModels.swift \
    PaperClip/WritingReviewModel.swift \
    PaperClip/WritingDraftModel.swift \
    PaperClip/WritingFullscreenPaperWidthPlan.swift \
    PaperClip/WritingDraftPersistenceModels.swift \
    Tests/WritingDraftPersistenceSupportTests.swift

run_swift_test WritingPersistenceTests \
    PaperClip/ModelContextHelpers.swift \
    PaperClip/WritingLanguageModels.swift \
    PaperClip/WritingPromptModel.swift \
    PaperClip/WritingPaperModels.swift \
    PaperClip/WritingDraftModel.swift \
    PaperClip/WritingReviewModel.swift \
    PaperClip/WritingPromptQueries.swift \
    PaperClip/WritingDraftQueries.swift \
    PaperClip/WritingReviewQueries.swift \
    PaperClip/WritingCascadeDeletion.swift \
    Tests/WritingPersistenceTests.swift

run_swift_test StatisticsSnapshotTests \
    PaperClip/AppStorageDirectory.swift \
    PaperClip/StoredFile.swift \
    PaperClip/AcademicTaxonomy.swift \
    PaperClip/Models.swift \
    PaperClip/MasteryStatusSegment.swift \
    PaperClip/MistakeTagModels.swift \
    PaperClip/MistakeModels.swift \
    PaperClip/MistakePracticeModels.swift \
    PaperClip/MistakePersistence.swift \
    PaperClip/MistakePracticePersistence.swift \
    PaperClip/MasteryStatusSummary.swift \
    PaperClip/MistakeClassification.swift \
    PaperClip/QuestionType.swift \
    PaperClip/ModelContextHelpers.swift \
    PaperClip/PreferredSubjects.swift \
    PaperClip/PDFPageIndexDisplay.swift \
    PaperClip/ExamModels.swift \
    PaperClip/ExamGradeMarkModel.swift \
    PaperClip/VocabularyJSONStorage.swift \
    PaperClip/VocabularyArticleRecitation.swift \
    PaperClip/VocabularyModels.swift \
    PaperClip/VocabularyCardDerivedProperties.swift \
    PaperClip/VocabularyPersistence.swift \
    PaperClip/VocabularyStudySessionItem.swift \
    PaperClip/VocabularyStudySessionMetrics.swift \
    PaperClip/VocabularyStudyModels.swift \
    PaperClip/StatisticsDataSeries.swift \
    PaperClip/StatisticsModels.swift \
    PaperClip/StatisticsCardAggregate.swift \
    PaperClip/StatisticsPracticeWeekData.swift \
    Tests/StatisticsSnapshotTests.swift

run_swift_test SubjectLibrarySnapshotTests \
    PaperClip/AppStorageDirectory.swift \
    PaperClip/StoredFile.swift \
    PaperClip/AcademicTaxonomy.swift \
    PaperClip/MasteryStatusSegment.swift \
    PaperClip/MasteryStatusSummary.swift \
    PaperClip/MistakeClassification.swift \
    PaperClip/QuestionType.swift \
    PaperClip/MistakeTagModels.swift \
    PaperClip/MistakeModels.swift \
    PaperClip/MistakePracticeModels.swift \
    PaperClip/MistakePersistence.swift \
    PaperClip/MistakePracticePersistence.swift \
    PaperClip/PDFPageIndexDisplay.swift \
    PaperClip/PDFPageSelectionSet.swift \
    PaperClip/PDFPageExportSelectionSupport.swift \
    PaperClip/PDFDocumentModels.swift \
    PaperClip/HandwritingLayerModel.swift \
    PaperClip/ExamModels.swift \
    PaperClip/ExamHandwritingLayerModel.swift \
    PaperClip/ExamGradeMarkModel.swift \
    PaperClip/ModelContextHelpers.swift \
    PaperClip/PDFPersistence.swift \
    PaperClip/PDFDocumentCascadeDeletion.swift \
    PaperClip/PreferredSubjects.swift \
    PaperClip/SubjectLibrarySnapshotSupport.swift \
    PaperClip/SubjectLibrarySnapshot.swift \
    PaperClip/SubjectDocumentSnapshot.swift \
    PaperClip/SubjectLibraryViewModels.swift \
    Tests/SubjectLibrarySnapshotTests.swift

run_swift_test VisibleElementDiffTests \
    PaperClip/VisibleElementDiff.swift \
    Tests/VisibleElementDiffTests.swift

run_swift_test ReviewSubmissionGeometryTests \
    PaperClip/ReviewSubmissionGeometry.swift \
    Tests/ReviewSubmissionGeometryTests.swift

run_swift_test ReviewSubmissionRenderLayoutTests \
    PaperClip/PDFLongImageLayoutSupport.swift \
    PaperClip/PDFLongImageStackLayoutSupport.swift \
    PaperClip/ReviewSubmissionGeometry.swift \
    PaperClip/ReviewSubmissionRenderLayout.swift \
    Tests/ReviewSubmissionRenderLayoutTests.swift

run_swift_test ReviewSubmissionSelectionSupportTests \
    PaperClip/ReviewSubmissionSelectionSupport.swift \
    Tests/ReviewSubmissionSelectionSupportTests.swift

run_swift_test ReviewSubmissionGenerationRequestTests \
    PaperClip/ReviewSubmissionGenerationRequest.swift \
    Tests/ReviewSubmissionGenerationRequestTests.swift

run_swift_test ScratchBoardGeometryTests \
    PaperClip/ScratchBoardModels.swift \
    PaperClip/ScratchBoardToolModels.swift \
    PaperClip/ScratchBoardInteractionModels.swift \
    PaperClip/ScratchBoardPanelGeometry.swift \
    PaperClip/ScratchBoardViewportLogic.swift \
    PaperClip/ScratchBoardCanvasOperations.swift \
    PaperClip/ScratchBoardShapeGeometry.swift \
    PaperClip/ScratchBoardShapePaths.swift \
    PaperClip/ScratchBoardPreviewPath.swift \
    PaperClip/ScratchBoardShapeHitTesting.swift \
    Tests/ScratchBoardGeometryTests.swift
