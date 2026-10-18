import SwiftUI

extension VocabularyTestView {
    func orderedStartQuestionValueBinding(maximumQuestionCount: Int) -> Binding<Int> {
        Binding(
            get: {
                let maximum = max(1, maximumQuestionCount)
                return min(max(1, Int(orderedStartQuestionText) ?? 1), maximum)
            },
            set: {
                let maximum = max(1, maximumQuestionCount)
                orderedStartQuestionText = String(min(max(1, $0), maximum))
            }
        )
    }

    func orderedQuestionCountValueBinding(maximumQuestionCount: Int) -> Binding<Int> {
        Binding(
            get: {
                let maximum = max(1, maximumQuestionCount)
                return min(max(1, Int(orderedQuestionCountText) ?? 1), maximum)
            },
            set: {
                let maximum = max(1, maximumQuestionCount)
                orderedQuestionCountText = String(min(max(1, $0), maximum))
            }
        )
    }

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
            batches: batches
        )

        Group {
            if batches.isEmpty {
                setupView(snapshot)
            } else {
                regularSessionView(snapshot)
            }
        }
        .navigationTitle(handwritingTestKind.navigationTitle)
        .navigationBarBackButtonHidden(isTestNavigationLocked)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if activeBatch?.status == .answering {
                    Button("返回", systemImage: "chevron.left") {
                        isConfirmingTestExit = true
                    }
                }
            }
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
            "结束本次测验？",
            isPresented: $isConfirmingTestExit,
            titleVisibility: .visible
        ) {
            Button("结束并批阅", role: .destructive) {
                finishTestEarly()
            }
            Button("继续测验", role: .cancel) {}
        } message: {
            Text("已作答内容将提交，所有未作答题目将按错误计入结果。")
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
                VocabularyAnswerAdvanceUndoBanner(
                    canUndo: canUndoLastAnswerAdvance,
                    undo: undoLastAnswerAdvance
                )
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
            dismissAnswerAdvanceUndo()
            cancelGradingTasks()
        }
    }

    var showsAnswerAdvanceAction: Bool {
        currentCard != nil
            && activeBatch?.status == .answering
    }

    var isTestNavigationLocked: Bool {
        activeBatch?.status == .answering || activeBatch?.status == .grading
    }

    var isLastQuestionInActiveBatch: Bool {
        currentIndex + 1 == (activeBatch?.cards.count ?? 0)
    }

    var answerAdvanceActionTitle: String {
        VocabularyAnsweringActionTitle.title(isLastInBatch: isLastQuestionInActiveBatch)
    }

    var emptyAnswerConfirmationActionTitle: String {
        isLastQuestionInActiveBatch ? answerAdvanceActionTitle : "跳过并进入下一题"
    }

    var canUndoLastAnswerAdvance: Bool {
        guard let target = answerAdvanceUndoTarget,
              batches.indices.contains(target.batchIndex) else { return false }
        return target.canRestore(
            currentBatchIndex: currentBatchIndex,
            currentQuestionIndex: currentIndex,
            currentAnswerHasInk: DrawingDataSupport.hasInk(currentDrawing),
            storedDrawingCount: batches[target.batchIndex].drawings.count
        )
    }

}
