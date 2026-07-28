import SwiftData
import SwiftUI

struct VocabularyContextPracticeView: View {
    let deck: VocabularyDeck

    @Environment(\.modelContext) private var modelContext
    @State private var output: VocabularyContextPracticeOutput?
    @State private var currentIndex = 0
    @State private var phase = VocabularyContextPracticePhase.preview
    @State private var response = ""
    @State private var currentResult: Bool?
    @State private var sessionItems: [VocabularyStudySessionItem] = []
    @State private var sessionID = UUID()
    @State private var sessionStartedAt = Date.now
    @State private var itemStartedAt = Date.now
    @State private var isGenerating = false
    @State private var generationID: UUID?
    @State private var generationTask: Task<Void, Never>?
    @State private var alert: AppAlert?

    @AppStorage("vocabularyArticle.gradePreset")
    private var storedGradePreset = VocabularyArticleGradePreset.juniorOneTwo.rawValue

    private let maximumCardCount = 6

    private var gradePreset: VocabularyArticleGradePreset {
        VocabularyArticleGradePreset(rawValue: storedGradePreset) ?? .juniorOneTwo
    }

    private var currentItem: VocabularyContextPracticeItem? {
        guard let output,
              output.lesson.items.indices.contains(currentIndex)
        else { return nil }
        return output.lesson.items[currentIndex]
    }

    var body: some View {
        Group {
            if isGenerating {
                ProgressView("正在生成本次语境练习…")
            } else if output == nil {
                introduction
            } else if let item = currentItem {
                practice(item)
            } else {
                completion
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("语境练习")
        .toolbar {
            if output != nil, !isGenerating {
                ToolbarItem(placement: .primaryAction) {
                    Button("生成新一轮", systemImage: "arrow.triangle.2.circlepath") {
                        startGeneration()
                    }
                }
            }
        }
        .appAlert($alert)
        .onDisappear {
            generationTask?.cancel()
            generationTask = nil
            generationID = nil
            isGenerating = false
        }
    }

    private var introduction: some View {
        ContentUnavailableView {
            Label("用语境主动回忆", systemImage: "text.bubble")
        } description: {
            Text("从到期和薄弱词中选择最多 \(maximumCardCount) 个词。先理解短句，再遮挡目标词进行回忆。")
        } actions: {
            VStack(spacing: 14) {
                Picker("适用年级", selection: $storedGradePreset) {
                    ForEach(VocabularyArticleGradePreset.allCases) { preset in
                        Text(preset.title).tag(preset.rawValue)
                    }
                }
                .pickerStyle(.menu)

                Button("生成本次练习", systemImage: "wand.and.stars") {
                    startGeneration()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func practice(_ item: VocabularyContextPracticeItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VocabularyProgressHeader(
                    index: currentIndex,
                    total: output?.lesson.items.count ?? 0
                )

                if phase == .preview {
                    preview(item)
                } else {
                    recall(item)
                }
            }
            .padding(28)
            .frame(maxWidth: 820, alignment: .leading)
        }
    }

    private func preview(_ item: VocabularyContextPracticeItem) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.term)
                    .font(.largeTitle.bold())
                    .textSelection(.enabled)
                Text(item.definition)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            GroupBox("高提示语境") {
                Text(item.sentence)
                    .font(.title3)
                    .lineSpacing(7)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }

            LabeledContent("常用搭配", value: item.collocation)
            if !item.usageTip.isEmpty {
                LabeledContent("用法提示", value: item.usageTip)
            }

            Button("遮住单词，开始回忆", systemImage: "eye.slash") {
                response = ""
                currentResult = nil
                phase = .recall
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func recall(_ item: VocabularyContextPracticeItem) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("根据释义和语境填空")
                .font(.headline)
            Text(item.definition)
                .font(.title2.bold())
            Text(item.cloze)
                .font(.system(.title2, design: .serif))
                .lineSpacing(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            TextField("输入缺少的英文", text: $response)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .disabled(currentResult != nil)
                .submitLabel(.done)
                .onSubmit {
                    if currentResult == nil {
                        check(item)
                    }
                }

            if let currentResult {
                Label(
                    currentResult ? "回答正确" : "正确答案：\(item.answer)",
                    systemImage: currentResult
                        ? "checkmark.circle.fill"
                        : "xmark.circle.fill"
                )
                .font(.headline)
                .foregroundStyle(currentResult ? Color.green : Color.red)

                Text(item.sentence)
                    .font(.body)
                    .foregroundStyle(.secondary)

                Button(
                    currentIndex + 1 == (output?.lesson.items.count ?? 0)
                        ? "完成"
                        : "下一题",
                    systemImage: "arrow.right"
                ) {
                    advance()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("检查", systemImage: "checkmark") {
                    check(item)
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
        }
    }

    private var completion: some View {
        let correctCount = sessionItems.filter(\.isCorrect).count
        return VocabularySessionCompleteView(
            title: "语境练习完成",
            message: "本轮完成 \(sessionItems.count) 题，答对 \(correctCount) 题。",
            systemImage: "text.bubble.fill"
        )
    }

    private func startGeneration() {
        guard !isGenerating else { return }

        let requestID = UUID()
        output = nil
        currentIndex = 0
        phase = .preview
        response = ""
        currentResult = nil
        sessionItems = []
        generationID = requestID
        isGenerating = true
        generationTask = Task {
            defer {
                if generationID == requestID {
                    isGenerating = false
                    generationID = nil
                    generationTask = nil
                }
            }

            do {
                let generatedOutput = try await VocabularyContextPracticeFlow.generate(
                    deck: deck,
                    gradePreset: gradePreset,
                    maximumCardCount: maximumCardCount,
                    modelContext: modelContext
                )
                try Task.checkCancellation()
                guard generationID == requestID else { return }

                output = generatedOutput
                currentIndex = 0
                phase = .preview
                response = ""
                currentResult = nil
                sessionItems = []
                sessionID = UUID()
                sessionStartedAt = .now
                itemStartedAt = .now
            } catch is CancellationError {
                return
            } catch {
                guard generationID == requestID, !Task.isCancelled else { return }
                alert = AppAlert(title: "无法生成语境练习", error: error)
            }
        }
    }

    private func check(_ item: VocabularyContextPracticeItem) {
        guard currentResult == nil,
              let card = output?.cardsByID[item.cardID]
        else { return }

        do {
            let sessionItem = try VocabularyContextPracticeFlow.recordAttempt(
                response: response,
                item: item,
                card: card,
                deck: deck,
                sessionID: sessionID,
                sessionStartedAt: sessionStartedAt,
                previousItems: sessionItems,
                duration: Date.now.timeIntervalSince(itemStartedAt),
                modelContext: modelContext
            )
            sessionItems.append(sessionItem)
            currentResult = sessionItem.isCorrect
        } catch {
            alert = AppAlert(title: "无法保存语境练习结果", error: error)
        }
    }

    private func advance() {
        guard currentResult != nil else { return }
        let nextIndex = currentIndex + 1
        currentIndex = nextIndex
        phase = .preview
        response = ""
        currentResult = nil
        itemStartedAt = .now
    }
}

private enum VocabularyContextPracticePhase {
    case preview
    case recall
}
