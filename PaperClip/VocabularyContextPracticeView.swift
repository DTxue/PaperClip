import SwiftData
import SwiftUI

struct VocabularyContextPracticeView: View {
    let deck: VocabularyDeck

    @Environment(\.modelContext) private var modelContext
    @State private var output: VocabularyContextPracticeOutput?
    @State private var currentIndex = 0
    @State private var isLoadingCache = true
    @State private var isGenerating = false
    @State private var generationID: UUID?
    @State private var generationTask: Task<Void, Never>?
    @State private var alert: AppAlert?

    @AppStorage("vocabularyContextPractice.gradePreset")
    private var storedGradePreset = VocabularyContextGradePreset.juniorOneTwo.rawValue

    private let maximumCardCount = 6

    private var gradePreset: VocabularyContextGradePreset {
        VocabularyContextGradePreset(rawValue: storedGradePreset) ?? .juniorOneTwo
    }

    private var cacheLoadID: String {
        "\(deck.id.uuidString).\(gradePreset.rawValue).\(maximumCardCount)"
    }

    private var currentItem: VocabularyContextPracticeItem? {
        guard let output,
              output.lesson.items.indices.contains(currentIndex)
        else { return nil }
        return output.lesson.items[currentIndex]
    }

    var body: some View {
        Group {
            if isLoadingCache {
                ProgressView("正在读取语境练习…")
            } else if isGenerating {
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
        .task(id: cacheLoadID) {
            loadCachedLesson()
        }
        .onDisappear {
            generationTask?.cancel()
            generationTask = nil
            generationID = nil
            isGenerating = false
        }
    }

    private var introduction: some View {
        ContentUnavailableView {
            Label("用语境理解单词", systemImage: "text.bubble")
        } description: {
            Text("从到期和薄弱词中选择最多 \(maximumCardCount) 个词，通过短句、搭配和用法提示加深理解。")
        } actions: {
            VStack(spacing: 14) {
                Picker("适用年级", selection: $storedGradePreset) {
                    ForEach(VocabularyContextGradePreset.allCases) { preset in
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
                contextCard(item)
            }
            .padding(28)
            .frame(maxWidth: 820, alignment: .leading)
        }
    }

    private func contextCard(_ item: VocabularyContextPracticeItem) -> some View {
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

            Button(
                currentIndex + 1 == (output?.lesson.items.count ?? 0)
                    ? "完成"
                    : "下一个词",
                systemImage: "arrow.right"
            ) {
                advance()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var completion: some View {
        return VocabularySessionCompleteView(
            title: "语境练习完成",
            message: "本轮学习了 \(output?.lesson.items.count ?? 0) 个词。",
            systemImage: "text.bubble.fill"
        )
    }

    private func startGeneration() {
        guard !isGenerating else { return }

        let requestID = UUID()
        isLoadingCache = false
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
            } catch is CancellationError {
                return
            } catch {
                guard generationID == requestID, !Task.isCancelled else { return }
                alert = AppAlert(title: "无法生成语境练习", error: error)
            }
        }
    }

    private func loadCachedLesson() {
        guard !isGenerating else {
            isLoadingCache = false
            return
        }

        defer { isLoadingCache = false }
        do {
            output = try VocabularyContextPracticeFlow.loadCached(
                deck: deck,
                gradePreset: gradePreset,
                maximumCardCount: maximumCardCount,
                modelContext: modelContext
            )
            currentIndex = 0
        } catch {
            alert = AppAlert(title: "无法读取语境练习", error: error)
        }
    }

    private func advance() {
        currentIndex += 1
    }
}
