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
    swiftc PaperClip/PaperClipSchemaVersion.swift "$@" -o "$BUILD_DIR/$name"
    "$BUILD_DIR/$name"
}

run_swift_test AIServiceModelsTests \
    PaperClip/AIResponseJSONValueExtractor.swift \
    PaperClip/AIResponseJSONSanitizer.swift \
    PaperClip/AIDecodingSupport.swift \
    PaperClip/AIServiceModels.swift \
    PaperClip/AIVocabularyModels.swift \
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
    PaperClip/VocabularyAIPrompts.swift \
    Tests/VocabularyAIPromptsTests.swift

run_swift_test VocabularyContextPracticeTests \
    PaperClip/VocabularyContextPractice.swift \
    PaperClip/VocabularyContextAIPrompts.swift \
    Tests/VocabularyContextPracticeTests.swift

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
    PaperClip/AIServiceResponsesPayloads.swift \
    Tests/AIServiceResponseDecodingTests.swift

run_swift_test ImageJPEGProfileTests \
    PaperClip/ImageJPEGProfile.swift \
    Tests/ImageJPEGProfileTests.swift

run_swift_test ImageEncodingPlanTests \
    PaperClip/ImageJPEGProfile.swift \
    PaperClip/ImageEncodingPlan.swift \
    Tests/ImageEncodingPlanTests.swift

run_swift_test PaperClipDataBackupServiceTests \
    PaperClip/AppStorageDirectory.swift \
    Tests/PaperClipDataBackupServiceTests.swift \
    -lsqlite3

run_swift_test LegacyMistakeDataCleanupTests \
    PaperClip/AppStorageDirectory.swift \
    PaperClip/LegacyMistakeDataCleanup.swift \
    Tests/LegacyMistakeDataCleanupTests.swift \
    -lsqlite3

LEGACY_STORE_FIXTURE_DIR="$BUILD_DIR/paperclip-legacy-store"
LEGACY_STORE_FIXTURE_ARCHIVE="$BUILD_DIR/PaperClipLegacyUnversionedStore.tar.gz"
rm -rf "$LEGACY_STORE_FIXTURE_DIR"
mkdir -p "$LEGACY_STORE_FIXTURE_DIR"
base64 -D < Tests/Fixtures/PaperClipLegacyUnversionedStore.tar.gz.base64 \
    > "$LEGACY_STORE_FIXTURE_ARCHIVE"
EXPECTED_LEGACY_FIXTURE_SHA256="$(< Tests/Fixtures/PaperClipLegacyUnversionedStore.sha256)"
ACTUAL_LEGACY_FIXTURE_SHA256="$(shasum -a 256 "$LEGACY_STORE_FIXTURE_ARCHIVE" | awk '{print $1}')"
if [[ "$ACTUAL_LEGACY_FIXTURE_SHA256" != "$EXPECTED_LEGACY_FIXTURE_SHA256" ]]; then
    echo "Legacy SwiftData fixture checksum mismatch" >&2
    exit 1
fi
tar -xzf "$LEGACY_STORE_FIXTURE_ARCHIVE" -C "$LEGACY_STORE_FIXTURE_DIR"
export PAPERCLIP_LEGACY_STORE_DIR="$LEGACY_STORE_FIXTURE_DIR"

run_swift_test PaperClipSchemaMigrationTests \
    PaperClip/Persistence/Compatibility/MistakeLibraryV2Model.swift \
    PaperClip/Persistence/Compatibility/PaperClipLegacySchemas.swift \
    PaperClip/Persistence/Compatibility/PaperClipMigrationPlan.swift \
    PaperClip/Persistence/Compatibility/VocabularyArticleModels.swift \
    PaperClip/AppStorageDirectory.swift \
    PaperClip/AcademicTaxonomy.swift \
    PaperClip/Persistence/Compatibility/PDFDocumentModels.swift \
    PaperClip/Persistence/Compatibility/HandwritingLayerModel.swift \
    PaperClip/Persistence/Compatibility/ExamModels.swift \
    PaperClip/Persistence/Compatibility/ExamPageSubmissionModel.swift \
    PaperClip/Persistence/Compatibility/ExamHandwritingLayerModel.swift \
    PaperClip/Persistence/Compatibility/ExamGradeMarkModel.swift \
    PaperClip/ModelContextHelpers.swift \
    PaperClip/Persistence/Compatibility/MistakeModels.swift \
    PaperClip/Persistence/Compatibility/ExportRecordModel.swift \
    PaperClip/Persistence/Compatibility/MistakePracticeModels.swift \
    PaperClip/Persistence/Compatibility/MistakeLibrarySchemaModels.swift \
    PaperClip/VocabularyCoreEnums.swift \
    PaperClip/VocabularyReviewRating.swift \
    PaperClip/VocabularyJSONStorage.swift \
    PaperClip/VocabularyStudySessionItem.swift \
    PaperClip/VocabularyStudySessionMetrics.swift \
    PaperClip/AIResponseJSONValueExtractor.swift \
    PaperClip/AIResponseJSONSanitizer.swift \
    PaperClip/AIDecodingSupport.swift \
    PaperClip/AIVocabularyModels.swift \
    PaperClip/VocabularyModels.swift \
    PaperClip/VocabularyMemoryModels.swift \
    PaperClip/VocabularyReviewModels.swift \
    PaperClip/VocabularyStudyModels.swift \
    PaperClip/Persistence/Compatibility/VocabularyTestPersistenceModels.swift \
    PaperClip/VocabularyHandwritingAttempt.swift \
    PaperClip/VocabularyImportModels.swift \
    PaperClip/VocabularyDistractorCache.swift \
    PaperClip/DiaryEntryContentPresence.swift \
    PaperClip/DiaryModels.swift \
    PaperClip/Persistence/Compatibility/WritingPromptModel.swift \
    PaperClip/Persistence/Compatibility/WritingDraftModel.swift \
    PaperClip/Persistence/Compatibility/WritingReviewModel.swift \
    PaperClip/PaperClipSchema.swift \
    Tests/PaperClipSchemaMigrationTests.swift \
    -lsqlite3


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
    PaperClip/DiaryViewModels.swift \
    PaperClip/AppStorageDirectory.swift \
    PaperClip/AIKnowledgeModels.swift \
    PaperClip/ModelContextHelpers.swift \
    PaperClip/DiaryEntryContentPresence.swift \
    PaperClip/DiaryModels.swift \
    PaperClip/KnowledgeItemAnalysisSupport.swift \
    PaperClip/DiaryKnowledgeSnapshot.swift \
    Tests/DiaryKnowledgeSnapshotTests.swift

run_swift_test KnowledgeAIPromptsTests \
    PaperClip/AIKnowledgeModels.swift \
    PaperClip/KnowledgeAnalysisDecodable.swift \
    PaperClip/KnowledgeAIAnalysisSubjectStrategies.swift \
    PaperClip/KnowledgeAIAnalysisOutputSchema.swift \
    PaperClip/KnowledgeAIPrompts.swift \
    Tests/KnowledgeAIPromptsTests.swift

run_swift_test HandwritingRenderGeometryTests \
    PaperClip/HandwritingRenderGeometry.swift \
    Tests/HandwritingRenderGeometryTests.swift

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
    PaperClip/VocabularyCoreEnums.swift \
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

run_swift_test VocabularyStudySessionItemFactoryTests \
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
    PaperClip/VocabularyStudySessionItemFactory.swift \
    Tests/VocabularyStudySessionItemFactoryTests.swift

run_swift_test VocabularyPersistenceTests \
    PaperClip/AIResponseJSONValueExtractor.swift \
    PaperClip/AIResponseJSONSanitizer.swift \
    PaperClip/AIDecodingSupport.swift \
    PaperClip/AIVocabularyModels.swift \
    PaperClip/ModelContextHelpers.swift \
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
    PaperClip/Persistence/Compatibility/VocabularyTestPersistenceModels.swift \
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
    PaperClip/VocabularyDelimitedTextParser.swift \
    PaperClip/VocabularyPairedLineTextParser.swift \
    PaperClip/VocabularyTextRowBuilder.swift \
    PaperClip/StringRegexSplitting.swift \
    Tests/VocabularyTextImporterTests.swift

run_swift_test StatisticsSnapshotTests \
    PaperClip/ModelContextHelpers.swift \
    PaperClip/VocabularyJSONStorage.swift \
    PaperClip/VocabularyModels.swift \
    PaperClip/VocabularyCardDerivedProperties.swift \
    PaperClip/VocabularyPersistence.swift \
    PaperClip/VocabularyStudySessionItem.swift \
    PaperClip/VocabularyStudySessionMetrics.swift \
    PaperClip/VocabularyStudyModels.swift \
    PaperClip/VocabularyStudySessionDraft.swift \
    PaperClip/VocabularyStudySessionTransaction.swift \
    PaperClip/StatisticsModels.swift \
    Tests/StatisticsSnapshotTests.swift
