import SwiftUI

extension VocabularyTestView {
    func questionCountSliderValue(maximumQuestionCount: Int) -> Binding<Double> {
        Binding(
            get: {
                Double(VocabularyTestQuestionCount.clamped(
                    questionCount,
                    maximumQuestionCount: maximumQuestionCount
                ))
            },
            set: {
                questionCount = VocabularyTestQuestionCount.clamped(
                    Int($0.rounded()),
                    maximumQuestionCount: maximumQuestionCount
                )
            }
        )
    }

    var activeBatch: VocabularyTestBatch? {
        guard batches.indices.contains(currentBatchIndex) else { return nil }
        return batches[currentBatchIndex]
    }

    @ViewBuilder
    var body: some View {
        let snapshot = VocabularyTestViewSnapshot(
            deckCards: allCards,
            deckDraft: latestDraft,
            batches: batches
        )

        Group {
            if batches.isEmpty {
                setupView(snapshot)
            } else if sessionMode == .regular {
                regularSessionView(snapshot)
            } else if !didFinishAnswering {
                answeringView(snapshot)
            } else if snapshot.hasPendingGrading {
                VocabularyTestExamFinalizingView(
                    gradedBatchCount: snapshot.gradedBatchCount,
                    batchCount: batches.count
                )
            } else if !snapshot.failedBatchIndices.isEmpty {
                VocabularyTestFailureView(
                    failedBatchIndices: snapshot.failedBatchIndices,
                    batches: batches,
                    retryAll: retryFailedBatches,
                    retryBatch: { startBatchGrading(batchIndex: $0, automaticRetry: false) }
                )
            } else {
                VocabularyTestResultsView(
                    title: "测验完成",
                    questions: snapshot.gradedQuestions,
                    enlargedImage: $enlargedImage
                )
            }
        }
        .navigationTitle("测验")
        .toolbar {
        }
        .appAlert($alert)
        .task(id: deck.id) {
            fetchSessionData()
        }
        .onDisappear {
            draftSaveAction.cancel()
            cancelGradingTasks()
            saveDraft()
        }
    }

    var showsExamExitButton: Bool {
        sessionMode == .exam && !batches.isEmpty
    }

}
