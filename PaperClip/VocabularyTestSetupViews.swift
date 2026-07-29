import SwiftUI

extension VocabularyTestView {
    func setupView(_ snapshot: VocabularyTestViewSnapshot) -> some View {
        let selectableRange = VocabularyTestQuestionCount.selectableRange(
            maximumQuestionCount: snapshot.maximumQuestionCount
        )
        let resolvedQuestionCount = selectedMode.resolvedQuestionCount(
            requestedQuestionCount: questionCount,
            maximumQuestionCount: snapshot.maximumQuestionCount
        )
        let canStart = selectedMode.canStart(cardCount: snapshot.deckCards.count)

        return Form {
            if handwritingTestKind == .englishDefinition {
                Section {
                    Label("题面显示单词，请手写词卡中保存的英文释义。", systemImage: "text.book.closed")
                    Text("批阅只忽略大小写、首尾标点和多余空格；其他差异均判为错误。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } footer: {
                    if snapshot.deckCards.isEmpty {
                        Text("当前词集没有已保存英文释义的词卡，请先在词集设置或词卡编辑中补充。")
                    }
                }
            }

            Section("模式") {
                Picker("测验模式", selection: $selectedMode) {
                    ForEach(VocabularyTestMode.setupModes) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if selectedMode == .debug {
                    Text("固定 5 题，仅测试手写与 AI 批阅，不记录历史或学习进度。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("题量") {
                if selectedMode == .debug {
                    LabeledContent("题目数量") {
                        Text("5 题")
                            .monospacedDigit()
                    }
                    .accessibilityValue("5 题")
                } else {
                    Stepper(
                        value: questionCountStepperValue(
                            maximumQuestionCount: snapshot.maximumQuestionCount
                        ),
                        in: selectableRange,
                        step: 1
                    ) {
                        LabeledContent("题目数量") {
                            Text("\(resolvedQuestionCount) 题")
                                .monospacedDigit()
                        }
                    }
                    .disabled(snapshot.deckCards.isEmpty)
                    .accessibilityValue("\(resolvedQuestionCount) 题")

                    if VocabularyTestQuestionCount.allowsSlider(
                        maximumQuestionCount: snapshot.maximumQuestionCount
                    ) {
                        Slider(
                            value: questionCountSliderValue(maximumQuestionCount: snapshot.maximumQuestionCount),
                            in: Double(selectableRange.lowerBound)...Double(selectableRange.upperBound),
                            step: 1
                        )
                        .disabled(snapshot.deckCards.isEmpty)
                        .accessibilityLabel("题目数量")
                        .accessibilityValue("\(resolvedQuestionCount) 题")
                    }
                }
            }

            Section {
                HStack {
                    Spacer()
                    Button {
                        startTest()
                    } label: {
                        Label(
                            selectedMode == .debug ? "开始调试" : "开始测验",
                            systemImage: selectedMode == .debug ? "ladybug.fill" : "play.fill"
                        )
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .disabled(!canStart)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } footer: {
                if selectedMode == .debug, !canStart {
                    Text("调试模式需要\(deck.kind.collectionName)中至少有 5 个\(deck.kind.itemName)。")
                } else if selectedMode == .debug {
                    Text("调试结果只在当前页面显示，退出后不会出现在历史记录中。")
                } else {
                    switch handwritingTestKind {
                    case .spelling:
                        Text("使用 Apple Pencil 手写英文答案，完成后由 AI 统一批改。题量至少为\(deck.kind.collectionName)总数的 60%。")
                    case .englishDefinition:
                        Text("AI 只识别笔迹，系统再与词卡英文释义严格比较。题量至少为可用词卡总数的 60%。")
                    }
                }
            }
        }
        .onAppear {
            questionCount = VocabularyTestQuestionCount.clamped(
                questionCount,
                maximumQuestionCount: snapshot.maximumQuestionCount
            )
        }
        .onChange(of: snapshot.deckCards.count) {
            questionCount = VocabularyTestQuestionCount.clamped(
                questionCount,
                maximumQuestionCount: snapshot.maximumQuestionCount
            )
        }
    }
}
