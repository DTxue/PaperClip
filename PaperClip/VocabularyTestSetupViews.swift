import SwiftUI

extension VocabularyTestView {
    func setupView(_ snapshot: VocabularyTestViewSnapshot) -> some View {
        let isEnglishDefinitionTest = handwritingTestKind == .englishDefinition
        let availableCardIDs = Set(snapshot.deckCards.map(\.id))
        let selectedCardCount = selectedEnglishDefinitionCardIDs
            .intersection(availableCardIDs)
            .count
        let standardSelectableRange = VocabularyTestQuestionCount.selectableRange(
            maximumQuestionCount: snapshot.maximumQuestionCount
        )
        let englishDefinitionSelectableRange = VocabularyEnglishDefinitionQuestionCount.selectableRange(
            maximumQuestionCount: snapshot.deckCards.count
        )
        let standardResolvedQuestionCount = selectedMode.resolvedQuestionCount(
            requestedQuestionCount: questionCount,
            maximumQuestionCount: snapshot.maximumQuestionCount
        )
        let englishDefinitionResolvedQuestionCount = VocabularyEnglishDefinitionQuestionCount.clamped(
            questionCount,
            maximumQuestionCount: snapshot.deckCards.count
        )
        let isDebugMode = !isEnglishDefinitionTest && selectedMode == .debug
        let canStart: Bool
        if isEnglishDefinitionTest {
            canStart = VocabularyEnglishDefinitionQuestionCount.canStart(
                availableQuestionCount: englishDefinitionTestMode == .custom
                    ? selectedCardCount
                    : snapshot.deckCards.count
            )
        } else {
            canStart = selectedMode.canStart(cardCount: snapshot.deckCards.count)
        }

        return Form {
            if isEnglishDefinitionTest {
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
                if isEnglishDefinitionTest {
                    Picker("出题模式", selection: $englishDefinitionTestMode) {
                        ForEach(VocabularyEnglishDefinitionTestMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                } else {
                    Picker("测验模式", selection: $selectedMode) {
                        ForEach(VocabularyTestMode.setupModes) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.inline)

                    if selectedMode == .debug {
                        Text("固定 5 题，仅测试手写与 AI 批阅，不记录历史或学习进度。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !isEnglishDefinitionTest, selectedMode != .debug {
                Section("出题方式") {
                    Picker("出题方式", selection: $selectedQuestionSelectionMode) {
                        ForEach(VocabularyTestQuestionSelectionMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.inline)

                    if selectedQuestionSelectionMode == .ordered {
                        let maximum = max(1, snapshot.deckCards.count)
                        let start = min(
                            max(1, Int(orderedStartQuestionText) ?? 1),
                            maximum
                        )
                        let availableCount = max(1, maximum - start + 1)
                        HStack(spacing: 6) {
                            Text("从第")
                            TextField("1", text: $orderedStartQuestionText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.center)
                                .frame(width: 52)
                            Stepper(
                                "",
                                value: orderedStartQuestionValueBinding(
                                    maximumQuestionCount: maximum
                                ),
                                in: 1...maximum
                            )
                            .labelsHidden()
                            .fixedSize()
                            Text("题开始，测验")
                            TextField("1", text: $orderedQuestionCountText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.center)
                                .frame(width: 52)
                            Stepper(
                                "",
                                value: orderedQuestionCountValueBinding(
                                    maximumQuestionCount: availableCount
                                ),
                                in: 1...availableCount
                            )
                            .labelsHidden()
                            .fixedSize()
                            Text("题")
                        }

                        if let start = Int(orderedStartQuestionText),
                           let questionCount = Int(orderedQuestionCountText),
                           let range = VocabularyTestQuestionRange.validated(
                               startQuestion: start,
                               questionCount: questionCount,
                               maximumQuestionCount: snapshot.deckCards.count
                           ) {
                            LabeledContent("实际范围") {
                                Text("第 \(range.lowerBound)–\(range.upperBound) 题")
                                    .monospacedDigit()
                            }
                        } else {
                            Text("范围超出当前 \(snapshot.deckCards.count) 题，请检查起始题号和测验题数。")
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Text("按 \(deck.kind.collectionName)当前顺序出题，从起始题开始测验指定题数。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("题量") {
                if isEnglishDefinitionTest, englishDefinitionTestMode == .custom {
                    NavigationLink {
                        VocabularyEnglishDefinitionCardSelectionView(
                            cards: snapshot.deckCards,
                            selectedCardIDs: $selectedEnglishDefinitionCardIDs
                        )
                    } label: {
                        LabeledContent("选择词语") {
                            Text("\(selectedCardCount) 题")
                                .monospacedDigit()
                        }
                    }
                    .accessibilityValue("已选择 \(selectedCardCount) 题")

                    Text("由你选择本次要手写的词语，至少选择 5 个。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if isEnglishDefinitionTest {
                    Stepper(
                        value: englishDefinitionQuestionCountStepperValue(
                            maximumQuestionCount: snapshot.deckCards.count
                        ),
                        in: englishDefinitionSelectableRange,
                        step: 1
                    ) {
                        LabeledContent("题目数量") {
                            Text("\(englishDefinitionResolvedQuestionCount) 题")
                                .monospacedDigit()
                        }
                    }
                    .disabled(snapshot.deckCards.count < VocabularyEnglishDefinitionQuestionCount.minimum)
                    .accessibilityValue("\(englishDefinitionResolvedQuestionCount) 题")

                    if VocabularyEnglishDefinitionQuestionCount.allowsSlider(
                        maximumQuestionCount: snapshot.deckCards.count
                    ) {
                        Slider(
                            value: englishDefinitionQuestionCountSliderValue(
                                maximumQuestionCount: snapshot.deckCards.count
                            ),
                            in: Double(englishDefinitionSelectableRange.lowerBound)...Double(
                                englishDefinitionSelectableRange.upperBound
                            ),
                            step: 1
                        )
                        .accessibilityLabel("题目数量")
                        .accessibilityValue("\(englishDefinitionResolvedQuestionCount) 题")
                    }

                    Text("每次从可用词语中随机抽取，题量最少为 5 题。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if selectedMode == .debug {
                    LabeledContent("题目数量") {
                        Text("5 题")
                            .monospacedDigit()
                    }
                    .accessibilityValue("5 题")
                } else if selectedQuestionSelectionMode == .ordered {
                    LabeledContent("题目数量") {
                        Text("\(Int(orderedQuestionCountText) ?? 0) 题")
                            .monospacedDigit()
                    }
                    Text("顺序出题不受常规测验最少 10 题限制，以输入的测验题数为准。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Stepper(
                        value: questionCountStepperValue(
                            maximumQuestionCount: snapshot.maximumQuestionCount
                        ),
                        in: standardSelectableRange,
                        step: 1
                    ) {
                        LabeledContent("题目数量") {
                            Text("\(standardResolvedQuestionCount) 题")
                                .monospacedDigit()
                        }
                    }
                    .disabled(snapshot.deckCards.isEmpty)
                    .accessibilityValue("\(standardResolvedQuestionCount) 题")

                    if VocabularyTestQuestionCount.allowsSlider(
                        maximumQuestionCount: snapshot.maximumQuestionCount
                    ) {
                        Slider(
                            value: questionCountSliderValue(maximumQuestionCount: snapshot.maximumQuestionCount),
                            in: Double(standardSelectableRange.lowerBound)...Double(
                                standardSelectableRange.upperBound
                            ),
                            step: 1
                        )
                        .disabled(snapshot.deckCards.isEmpty)
                        .accessibilityLabel("题目数量")
                        .accessibilityValue("\(standardResolvedQuestionCount) 题")
                    }
                }
            }

            Section {
                Button {
                    startTest()
                } label: {
                    Label(
                        isDebugMode ? "开始调试" : "开始测验",
                        systemImage: isDebugMode ? "ladybug.fill" : "play.fill"
                    )
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canStart)
            } footer: {
                if isEnglishDefinitionTest,
                   snapshot.deckCards.count < VocabularyEnglishDefinitionQuestionCount.minimum {
                    Text("当前只有 \(snapshot.deckCards.count) 个已保存英文释义的词语，至少需要 5 个才能开始。")
                } else if isEnglishDefinitionTest,
                          englishDefinitionTestMode == .custom,
                          selectedCardCount < VocabularyEnglishDefinitionQuestionCount.minimum {
                    Text("还需选择 \(VocabularyEnglishDefinitionQuestionCount.minimum - selectedCardCount) 个词语。")
                } else if isEnglishDefinitionTest {
                    Text("AI 只识别笔迹，系统再与词卡英文释义严格比较。")
                } else if selectedMode == .debug, !canStart {
                    Text("调试模式需要\(deck.kind.collectionName)中至少有 5 个\(deck.kind.itemName)。")
                } else if selectedMode == .debug {
                    Text("调试结果只在当前页面显示，退出后不会出现在历史记录中。")
                } else if deck.kind == .dictationChinese {
                    Text("使用 Apple Pencil 手写默写内容，系统将通过本地文字识别逐字比较；无法辨认的字可能会判错。")
                } else {
                    Text("使用 Apple Pencil 手写英文答案，完成后由 AI 统一批改。随机出题时题量最少为 10 题；\(deck.kind.collectionName)不足 10 题时使用全部题目。")
                }
            }
        }
        .controlSize(.large)
        .task(id: availableCardIDs) {
            synchronizeSetupState(
                maximumQuestionCount: snapshot.maximumQuestionCount,
                availableCardIDs: availableCardIDs
            )
        }
    }

    private func synchronizeSetupState(
        maximumQuestionCount: Int,
        availableCardIDs: Set<UUID>
    ) {
        let availableSelections = selectedEnglishDefinitionCardIDs
            .intersection(availableCardIDs)
        if selectedEnglishDefinitionCardIDs != availableSelections {
            selectedEnglishDefinitionCardIDs = availableSelections
        }
        if handwritingTestKind == .englishDefinition {
            let correctedQuestionCount = VocabularyEnglishDefinitionQuestionCount.clamped(
                questionCount,
                maximumQuestionCount: availableCardIDs.count
            )
            if questionCount != correctedQuestionCount {
                questionCount = correctedQuestionCount
            }
        } else {
            let correctedQuestionCount = VocabularyTestQuestionCount.clamped(
                questionCount,
                maximumQuestionCount: maximumQuestionCount
            )
            if questionCount != correctedQuestionCount {
                questionCount = correctedQuestionCount
            }
        }

    }
}

private struct VocabularyEnglishDefinitionCardSelectionView: View {
    let cards: [VocabularyCard]
    @Binding var selectedCardIDs: Set<UUID>

    var body: some View {
        List {
            Section {
                LabeledContent("已选择") {
                    Text("\(selectedCardIDs.intersection(Set(cards.map(\.id))).count) 题")
                        .monospacedDigit()
                }
            } footer: {
                Text("英文释义手写至少选择 5 个词语。")
            }

            Section("可选词语") {
                ForEach(cards) { card in
                    Toggle(isOn: selectionBinding(for: card.id)) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(card.term)
                            if !card.definition.isEmpty {
                                Text(card.definition)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("选择词语")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("清空") {
                    selectedCardIDs.removeAll()
                }
                .disabled(selectedCardIDs.isEmpty)

                Button("全选") {
                    selectedCardIDs = Set(cards.map(\.id))
                }
                .disabled(selectedCardIDs.count == cards.count)
            }
        }
    }

    private func selectionBinding(for cardID: UUID) -> Binding<Bool> {
        Binding(
            get: { selectedCardIDs.contains(cardID) },
            set: { isSelected in
                if isSelected {
                    selectedCardIDs.insert(cardID)
                } else {
                    selectedCardIDs.remove(cardID)
                }
            }
        )
    }
}
