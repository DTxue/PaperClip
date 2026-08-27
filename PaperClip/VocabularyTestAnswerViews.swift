import SwiftUI

extension VocabularyTestView {
    func questionCountStepperValue(maximumQuestionCount: Int) -> Binding<Int> {
        Binding(
            get: {
                VocabularyTestQuestionCount.clamped(
                    questionCount,
                    maximumQuestionCount: maximumQuestionCount
                )
            },
            set: {
                questionCount = VocabularyTestQuestionCount.clamped(
                    $0,
                    maximumQuestionCount: maximumQuestionCount
                )
            }
        )
    }

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

    func englishDefinitionQuestionCountStepperValue(maximumQuestionCount: Int) -> Binding<Int> {
        Binding(
            get: {
                VocabularyEnglishDefinitionQuestionCount.clamped(
                    questionCount,
                    maximumQuestionCount: maximumQuestionCount
                )
            },
            set: {
                questionCount = VocabularyEnglishDefinitionQuestionCount.clamped(
                    $0,
                    maximumQuestionCount: maximumQuestionCount
                )
            }
        )
    }

    func englishDefinitionQuestionCountSliderValue(maximumQuestionCount: Int) -> Binding<Double> {
        Binding(
            get: {
                Double(VocabularyEnglishDefinitionQuestionCount.clamped(
                    questionCount,
                    maximumQuestionCount: maximumQuestionCount
                ))
            },
            set: {
                questionCount = VocabularyEnglishDefinitionQuestionCount.clamped(
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
            } else if sessionMode != .exam {
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
                    title: handwritingTestKind.completionTitle,
                    handwritingTestKind: handwritingTestKind,
                    questions: snapshot.gradedQuestions,
                    enlargedImage: $enlargedImage
                )
            }
        }
        .navigationTitle(handwritingTestKind.navigationTitle)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if showsAnswerAdvanceAction {
                    if isLastQuestionInActiveBatch {
                        Button(answerAdvanceActionTitle, systemImage: "checkmark.circle.fill") {
                            requestAdvanceQuestion()
                        }
                    } else {
                        VocabularyPencilOnlyActionButton(
                            title: answerAdvanceActionTitle,
                            systemImage: "arrow.right",
                            action: requestAdvanceQuestion
                        )
                    }
                }
            }
        }
        .confirmationDialog(
            "当前题尚未作答",
            isPresented: $isConfirmingEmptyAnswer,
            titleVisibility: .visible
        ) {
            Button(emptyAnswerConfirmationActionTitle) {
                advanceQuestion()
            }
            Button("继续作答", role: .cancel) {}
        } message: {
            Text("没有检测到手写内容。确认后将以空白答案继续。")
        }
        .overlay(alignment: .bottom) {
            if answerAdvanceUndoTarget != nil {
                VocabularyAnswerAdvanceUndoBanner(undo: undoLastAnswerAdvance)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: answerAdvanceUndoTarget)
        .appAlert($alert)
        .task(id: deck.id) {
            fetchSessionData()
        }
        .onDisappear {
            draftSaveAction.cancel()
            dismissAnswerAdvanceUndo()
            cancelGradingTasks()
            saveDraft()
        }
    }

    var showsAnswerAdvanceAction: Bool {
        !didFinishAnswering
            && currentCard != nil
            && activeBatch?.status == .answering
    }

    var isLastQuestionInActiveBatch: Bool {
        currentIndex + 1 == (activeBatch?.cards.count ?? 0)
    }

    var answerAdvanceActionTitle: String {
        VocabularyAnsweringActionTitle.title(
            isExam: sessionMode == .exam,
            isLastInBatch: isLastQuestionInActiveBatch,
            isLastBatch: currentBatchIndex + 1 == batches.count
        )
    }

    var emptyAnswerConfirmationActionTitle: String {
        isLastQuestionInActiveBatch ? answerAdvanceActionTitle : "跳过并进入下一题"
    }

    var showsExamExitButton: Bool {
        sessionMode == .exam && !batches.isEmpty
    }

}
