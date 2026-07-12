import Foundation
import SwiftData
import SwiftUI
import UIKit

struct VocabularyArticleView: View {
    let deck: VocabularyDeck

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.paperClipAppTheme) private var appTheme
    @Environment(\.paperClipReadingTheme) private var readingTheme
    @StateObject private var speechRecognizer = VocabularyArticleSpeechRecognizer()
    @State private var cards: [VocabularyCard] = []
    @State private var articles: [VocabularyGeneratedArticle] = []
    @State private var article: VocabularyGeneratedArticle?
    @State private var recitation = VocabularyArticleRecitationState(sentences: [])
    @State private var recitationHistories: [VocabularyArticleRecitationHistory] = []
    @State private var viewMode: VocabularyArticleViewMode = .reading
    @State private var listeningBaseline: VocabularyArticleRecitationState?
    @State private var sessionStartedAt: Date?
    @State private var stuckSentenceIndexes: Set<Int> = []
    @State private var completionFeedbackTick = 0
    @State private var isGenerating = false
    @State private var generationProgressText = ""
    @State private var isShowingGenerationSettings = false
    @State private var isConfirmingReplacement = false
    @State private var generationConfiguration = VocabularyArticleGenerationConfiguration.default
    @State private var pendingGenerationConfiguration: VocabularyArticleGenerationConfiguration?
    @State private var generationID: UUID?
    @State private var generationTask: Task<Void, Never>?
    @State private var alert: AppAlert?

    @AppStorage("vocabularyArticle.gradePreset") private var storedGradePreset = VocabularyArticleGradePreset.juniorOneTwo.rawValue
    @AppStorage("vocabularyArticle.preferredStoryCount") private var storedStoryCount = 3
    @AppStorage("vocabularyArticle.selectedGenres") private var storedGenres = "campus|adventure"
    @AppStorage("vocabularyArticle.customGenre") private var storedCustomGenre = ""

    private var readingPalette: PaperClipReadingPalette {
        readingTheme.palette(for: colorScheme, appTheme: appTheme)
    }

    private var modeSelection: Binding<VocabularyArticleViewMode> {
        Binding(
            get: { viewMode },
            set: { targetMode in
                guard VocabularyArticleModePolicy.canSelect(
                    targetMode,
                    currentMode: viewMode,
                    isRecitationComplete: recitation.isComplete
                ) else { return }

                viewMode = targetMode
            }
        )
    }

    var body: some View {
        Group {
            if cards.isEmpty {
                ContentUnavailableView(
                    "还没有单词",
                    systemImage: "textformat.abc",
                    description: Text("新增或导入单词后，可以生成词生文。")
                )
            } else if let article {
                articleContent(article)
            } else {
                ContentUnavailableView {
                    Label("还没有词生文", systemImage: "text.book.closed")
                } description: {
                    Text("把当前词集拆分成适合单独阅读和背诵的英文故事系列。")
                } actions: {
                    Button("生成词生文", systemImage: "wand.and.stars") {
                        presentGenerationSettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isGenerating)
                }
            }
        }
        .overlay {
            if isGenerating {
                ProgressView(generationProgressText.isEmpty ? "正在生成词生文..." : generationProgressText)
                    .padding(20)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if article != nil {
                    Button("重新生成", systemImage: "arrow.triangle.2.circlepath") {
                        presentGenerationSettings()
                    }
                    .disabled(isGenerating)
                }
            }
        }
        .confirmationDialog(
            "替换现有词生文？",
            isPresented: $isConfirmingReplacement,
            titleVisibility: .visible
        ) {
            Button("重新生成并替换", role: .destructive) {
                guard let configuration = pendingGenerationConfiguration else { return }
                startArticleGeneration(
                    configuration: configuration,
                    replacementConfirmed: true
                )
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("生成完成后会显示新的故事系列；旧文章和旧背诵记录仍会保留。")
        }
        .sheet(isPresented: $isShowingGenerationSettings) {
            VocabularyArticleGenerationSettingsView(
                configuration: $generationConfiguration,
                cardCount: cards.count,
                onCancel: { isShowingGenerationSettings = false },
                onGenerate: submitGenerationSettings
            )
        }
        .appAlert($alert)
        .task(id: deck.id) {
            loadData()
        }
        .onChange(of: speechRecognizer.transcript) { _, transcript in
            processTranscript(transcript)
        }
        .onChange(of: viewMode) { _, mode in
            if mode == .reading {
                speechRecognizer.stop()
            }
        }
        .onDisappear {
            generationTask?.cancel()
            generationTask = nil
            generationID = nil
            isGenerating = false
            generationProgressText = ""
            pendingGenerationConfiguration = nil
            speechRecognizer.stop()
        }
        .sensoryFeedback(.success, trigger: completionFeedbackTick)
    }

    private func articleContent(_ article: VocabularyGeneratedArticle) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if articles.count > 1 {
                    VocabularyArticleSeriesSelector(
                        articles: articles,
                        selectedArticleID: article.id,
                        onSelect: selectArticle
                    )
                }

                VocabularyArticleHeaderView(
                    title: article.title,
                    modelName: article.modelName,
                    cardCount: coveredTermCount(article),
                    palette: readingPalette
                )

                HStack {
                    Picker("词生文模式", selection: modeSelection) {
                        ForEach(VocabularyArticleViewMode.allCases) { mode in
                            Label(mode.title, systemImage: mode.systemImage)
                                .tag(mode)
                                .disabled(!VocabularyArticleModePolicy.canSelect(
                                    mode,
                                    currentMode: viewMode,
                                    isRecitationComplete: recitation.isComplete
                                ))
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 360)

                    Spacer(minLength: 0)
                }

                if viewMode == .reading {
                    VocabularyArticleReadingTextView(articleText: article.articleText, palette: readingPalette) {
                        viewMode = .recitation
                    }
                } else {
                    VocabularyArticleRecitationSummaryView(
                        histories: recitationHistories,
                        palette: readingPalette
                    )

                    recitationControls

                    VocabularyArticleMaskedTextView(
                        sentences: recitation.sentences,
                        revealedSentenceCount: recitation.revealedSentenceCount,
                        currentSentenceIndex: recitation.currentSentenceIndex,
                        currentWordIndex: recitation.currentWordIndex,
                        isComplete: recitation.isComplete,
                        palette: readingPalette
                    )

                    if let mismatch = recitation.lastMismatchWord {
                        Label("检测到不匹配：\(mismatch)。请从当前句开头重新背诵。", systemImage: "exclamationmark.triangle")
                            .font(.callout)
                            .foregroundStyle(.orange)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(readingPalette.warningBackgroundColor, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .frame(maxWidth: 980, alignment: .leading)
        }
        .background(readingPalette.pageBackgroundColor)
    }

    private var recitationControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                HStack(spacing: 10) {
                    Button(
                        speechRecognizer.isRecording ? "停止背诵" : speechRecognizer.isStarting ? "正在启动" : "开始背诵",
                        systemImage: speechRecognizer.isRecording ? "stop.circle" : "mic.circle"
                    ) {
                        Task {
                            if speechRecognizer.isRecording {
                                speechRecognizer.stop()
                            } else {
                                await startListening()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(recitation.sentences.isEmpty || recitation.isComplete || speechRecognizer.isStarting)

                    Button("重置", systemImage: "arrow.counterclockwise") {
                        speechRecognizer.stop()
                        listeningBaseline = nil
                        sessionStartedAt = nil
                        stuckSentenceIndexes = []
                        recitation.reset()
                    }
                    .buttonStyle(.bordered)
                    .disabled(recitation.sentences.isEmpty)
                }

                Spacer(minLength: 12)

                VocabularyArticleRecitationStatusView(
                    sentenceText: recitation.isComplete
                        ? "已完成"
                        : "第 \(min(recitation.currentSentenceIndex + 1, recitation.sentences.count))/\(recitation.sentences.count) 句",
                    progressText: recitation.currentProgressText,
                    isRecording: speechRecognizer.isRecording,
                    isComplete: recitation.isComplete,
                    palette: readingPalette
                )
            }

            if speechRecognizer.isRecording || !speechRecognizer.transcript.isEmpty {
                Divider()
                    .overlay(readingPalette.borderColor)

                VStack(alignment: .leading, spacing: 6) {
                    Label("识别文本", systemImage: "quote.bubble")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(readingPalette.secondaryTextColor)

                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(speechRecognizer.transcript.isEmpty ? "..." : speechRecognizer.transcript)
                            .font(.callout)
                            .foregroundStyle(readingPalette.primaryTextColor)
                            .textSelection(.enabled)
                            .padding(.vertical, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(readingPalette.panelBackgroundColor, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(readingPalette.borderColor.opacity(0.7), lineWidth: 1)
        }
    }

    private func loadData() {
        do {
            cards = try modelContext.fetchVocabularyArticleCards(deckID: deck.id)
            articles = try modelContext.fetchVocabularyGeneratedArticleSeries(deckID: deck.id)
            article = articles.first
            resetRecitation()
            loadRecitationHistories()
        } catch {
            alert = AppAlert(title: "无法读取词生文", error: error)
        }
    }

    private func presentGenerationSettings() {
        generationConfiguration = storedGenerationConfiguration
        isShowingGenerationSettings = true
    }

    private func submitGenerationSettings() {
        guard generationConfiguration.isValid else { return }
        saveGenerationConfiguration(generationConfiguration)
        isShowingGenerationSettings = false
        pendingGenerationConfiguration = generationConfiguration

        switch VocabularyArticleReplacementPolicy.nextStep(hasExistingArticle: !articles.isEmpty) {
        case .generate:
            startArticleGeneration(
                configuration: generationConfiguration,
                replacementConfirmed: false
            )
        case .confirmReplacement:
            isConfirmingReplacement = true
        }
    }

    private func startArticleGeneration(
        configuration: VocabularyArticleGenerationConfiguration,
        replacementConfirmed: Bool
    ) {
        guard !isGenerating else { return }
        let requestID = UUID()
        isGenerating = true
        generationProgressText = "正在准备故事系列..."
        generationID = requestID
        generationTask = Task {
            await generateArticleSeries(
                configuration: configuration,
                replacementConfirmed: replacementConfirmed,
                requestID: requestID
            )
        }
    }

    private func generateArticleSeries(
        configuration: VocabularyArticleGenerationConfiguration,
        replacementConfirmed: Bool,
        requestID: UUID
    ) async {
        do {
            defer {
                if generationID == requestID {
                    isGenerating = false
                    generationProgressText = ""
                    generationID = nil
                    generationTask = nil
                    pendingGenerationConfiguration = nil
                }
            }

            try Task.checkCancellation()

            let latestCards = try modelContext.fetchVocabularyArticleCards(deckID: deck.id)
            guard !latestCards.isEmpty else {
                cards = []
                articles = []
                article = nil
                return
            }

            let inputs = latestCards.map { VocabularyArticleCardInput(card: $0) }
            let plan = VocabularyArticleGenerationPlan.make(
                cards: inputs,
                configuration: configuration
            )
            let seriesID = [
                "v2",
                VocabularyArticleSourceFingerprint.make(cards: inputs),
                requestID.uuidString.lowercased()
            ].joined(separator: ":")
            var drafts: [VocabularyArticleDraft] = []
            drafts.reserveCapacity(plan.stories.count)
            for story in plan.stories {
                try Task.checkCancellation()
                generationProgressText = "正在生成第 \(story.index + 1)/\(story.totalCount) 篇..."
                drafts.append(try await AIService.generateVocabularyArticle(
                    story: story,
                    seriesID: seriesID
                ))
            }
            try Task.checkCancellation()

            let existingSeries = try modelContext.fetchVocabularyGeneratedArticleSeries(deckID: deck.id)
            guard VocabularyArticleReplacementPolicy.canCommit(
                hasExistingArticle: !existingSeries.isEmpty,
                replacementConfirmed: replacementConfirmed,
                isCancelled: Task.isCancelled,
                isCurrentRequest: generationID == requestID
            ) else {
                return
            }

            let storedArticles = try modelContext.insertVocabularyGeneratedArticleSeries(
                deckID: deck.id,
                drafts: drafts
            )
            try modelContext.save()
            cards = latestCards
            articles = storedArticles
            article = storedArticles.first
            resetRecitation()
            loadRecitationHistories()
            viewMode = .reading
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            alert = AppAlert(title: "无法生成词生文", error: error)
        }
    }

    private var storedGenerationConfiguration: VocabularyArticleGenerationConfiguration {
        let gradePreset = VocabularyArticleGradePreset(rawValue: storedGradePreset) ?? .juniorOneTwo
        let genres = Set(
            storedGenres
                .split(separator: "|")
                .compactMap { VocabularyArticleGenre(rawValue: String($0)) }
        )
        return VocabularyArticleGenerationConfiguration(
            gradePreset: gradePreset,
            preferredStoryCount: max(storedStoryCount, 1),
            selectedGenres: genres,
            customGenre: storedCustomGenre
        )
    }

    private func saveGenerationConfiguration(
        _ configuration: VocabularyArticleGenerationConfiguration
    ) {
        storedGradePreset = configuration.gradePreset.rawValue
        storedStoryCount = configuration.preferredStoryCount
        storedGenres = VocabularyArticleGenre.allCases
            .filter(configuration.selectedGenres.contains)
            .map(\.rawValue)
            .joined(separator: "|")
        storedCustomGenre = configuration.customGenre
    }

    private func selectArticle(_ selectedArticle: VocabularyGeneratedArticle) {
        guard selectedArticle.id != article?.id else { return }
        article = selectedArticle
        viewMode = .reading
        resetRecitation()
        loadRecitationHistories()
    }

    private func coveredTermCount(_ article: VocabularyGeneratedArticle) -> Int {
        guard let data = article.coveredTermsJSON.data(using: .utf8),
              let terms = try? JSONDecoder().decode([String].self, from: data)
        else { return 0 }
        return terms.count
    }

    private func resetRecitation() {
        speechRecognizer.stop()
        listeningBaseline = nil
        sessionStartedAt = nil
        stuckSentenceIndexes = []
        recitation = VocabularyArticleRecitationState(
            sentences: VocabularyArticleSentence.split(article?.articleText ?? "")
        )
    }

    private func startListening() async {
        guard !speechRecognizer.isRecording, !speechRecognizer.isStarting else { return }
        do {
            listeningBaseline = recitation
            sessionStartedAt = sessionStartedAt ?? Date()
            try await speechRecognizer.start()
        } catch {
            listeningBaseline = nil
            alert = AppAlert(title: "无法开始语音识别", error: error)
        }
    }

    private func processTranscript(_ transcript: String) {
        let baseline = listeningBaseline ?? recitation
        let previousRecitation = recitation
        let nextRecitation = VocabularyArticleTranscriptMatcher.apply(
            transcript: transcript,
            baseline: baseline,
            current: recitation
        )
        guard nextRecitation != recitation else { return }

        recitation = nextRecitation
        if nextRecitation.lastMismatchWord != nil {
            stuckSentenceIndexes.insert(previousRecitation.currentSentenceIndex)
        }
        if nextRecitation.revealedSentenceCount > previousRecitation.revealedSentenceCount {
            completionFeedbackTick += 1
        }
        if recitation.isComplete {
            listeningBaseline = nil
            speechRecognizer.stop()
            recordRecitationCompletion()
        }
    }

    private func loadRecitationHistories() {
        guard let article else {
            recitationHistories = []
            return
        }

        do {
            recitationHistories = try modelContext.fetchVocabularyArticleRecitationHistories(
                articleID: article.id
            )
        } catch {
            alert = AppAlert(title: "无法读取背诵记录", error: error)
        }
    }

    private func recordRecitationCompletion() {
        guard let article, let sessionStartedAt else { return }
        let duration = max(0, Date().timeIntervalSince(sessionStartedAt))
        let wordCount = recitation.sentences.reduce(0) { $0 + $1.words.count }

        _ = modelContext.recordVocabularyArticleRecitationHistory(
            article: article,
            duration: duration,
            sentenceCount: recitation.sentences.count,
            wordCount: wordCount,
            stuckSentenceIndexes: Array(stuckSentenceIndexes)
        )

        do {
            try modelContext.save()
            self.sessionStartedAt = nil
            stuckSentenceIndexes = []
            loadRecitationHistories()
        } catch {
            alert = AppAlert(title: "无法保存背诵记录", error: error)
        }
    }
}

private struct VocabularyArticleSeriesSelector: View {
    let articles: [VocabularyGeneratedArticle]
    let selectedArticleID: UUID
    let onSelect: (VocabularyGeneratedArticle) -> Void

    private var selectedIndex: Int {
        (articles.firstIndex { $0.id == selectedArticleID } ?? 0) + 1
    }

    var body: some View {
        HStack(spacing: 12) {
            Label("故事系列", systemImage: "books.vertical")
                .font(.headline)

            Spacer(minLength: 8)

            Menu {
                ForEach(Array(articles.enumerated()), id: \.element.id) { index, article in
                    Button {
                        onSelect(article)
                    } label: {
                        if article.id == selectedArticleID {
                            Label("第 \(index + 1) 篇 · \(article.title)", systemImage: "checkmark")
                        } else {
                            Text("第 \(index + 1) 篇 · \(article.title)")
                        }
                    }
                }
            } label: {
                Label("第 \(selectedIndex)/\(articles.count) 篇", systemImage: "chevron.up.chevron.down")
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct VocabularyArticleGenerationSettingsView: View {
    @Binding var configuration: VocabularyArticleGenerationConfiguration
    let cardCount: Int
    let onCancel: () -> Void
    let onGenerate: () -> Void

    private var resolvedStoryCount: Int {
        configuration.resolvedStoryCount(cardCount: cardCount)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("适用年级") {
                    Picker("年级预设", selection: $configuration.gradePreset) {
                        ForEach(VocabularyArticleGradePreset.allCases) { preset in
                            Text(preset.title).tag(preset)
                        }
                    }
                }

                Section("生成篇数") {
                    Stepper(
                        "期望生成 \(configuration.preferredStoryCount) 篇",
                        value: $configuration.preferredStoryCount,
                        in: 1...20
                    )
                    if resolvedStoryCount > configuration.preferredStoryCount {
                        Text("为覆盖全部 \(cardCount) 个词条并控制每篇长度，实际会生成 \(resolvedStoryCount) 篇。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("故事题材（可多选）") {
                    ForEach(VocabularyArticleGenre.allCases) { genre in
                        Toggle(genre.title, isOn: genreBinding(genre))
                    }
                    TextField("自定义题材，例如：校园机器人比赛", text: $configuration.customGenre)
                }

                Section("生成预览") {
                    LabeledContent("实际篇数", value: "\(resolvedStoryCount) 篇")
                    LabeledContent("每篇目标词", value: "最多 \(configuration.gradePreset.termsPerStory) 个")
                    LabeledContent(
                        "每篇篇幅",
                        value: "\(configuration.gradePreset.targetWordRange.lowerBound)–\(configuration.gradePreset.targetWordRange.upperBound) 词"
                    )
                    LabeledContent("词条覆盖", value: "\(cardCount)/\(cardCount)")
                }
            }
            .navigationTitle("词生文设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("开始生成", action: onGenerate)
                        .disabled(!configuration.isValid || cardCount == 0)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func genreBinding(_ genre: VocabularyArticleGenre) -> Binding<Bool> {
        Binding(
            get: { configuration.selectedGenres.contains(genre) },
            set: { isSelected in
                if isSelected {
                    configuration.selectedGenres.insert(genre)
                } else {
                    configuration.selectedGenres.remove(genre)
                }
            }
        )
    }
}

private struct VocabularyArticleHeaderView: View {
    let title: String
    let modelName: String
    let cardCount: Int
    let palette: PaperClipReadingPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(palette.primaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Label(modelName, systemImage: "cpu")
                Divider()
                    .frame(height: 14)
                    .overlay(palette.borderColor)
                Label("\(cardCount) 个词条", systemImage: "textformat.abc")
            }
            .font(.subheadline)
            .foregroundStyle(palette.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 2)
    }
}

private struct VocabularyArticleRecitationStatusView: View {
    let sentenceText: String
    let progressText: String
    let isRecording: Bool
    let isComplete: Bool
    let palette: PaperClipReadingPalette

    var body: some View {
        HStack(spacing: 8) {
            statusLabel(
                sentenceText,
                systemImage: isComplete ? "checkmark.circle.fill" : "text.alignleft",
                tint: isComplete ? .green : palette.secondaryTextColor
            )
            statusLabel(progressText, systemImage: "waveform", tint: palette.secondaryTextColor)
            if isRecording {
                statusLabel("正在听写", systemImage: "mic.fill", tint: palette.accentColor)
            }
        }
        .font(.callout)
    }

    private func statusLabel(_ text: String, systemImage: String, tint: Color) -> some View {
        Label(text, systemImage: systemImage)
            .foregroundStyle(tint)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(palette.chipBackgroundColor, in: Capsule())
    }
}

private struct VocabularyArticleRecitationSummaryView: View {
    let histories: [VocabularyArticleRecitationHistory]
    let palette: PaperClipReadingPalette

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 12, alignment: .leading)
    ]

    private var averageDuration: Double {
        guard !histories.isEmpty else { return 0 }
        let totalDuration = histories.reduce(0) { $0 + $1.duration }
        return totalDuration / Double(histories.count)
    }

    private var lastCompletedText: String {
        guard let latest = histories.first?.completedAt else { return "暂无" }
        return latest.formatted(date: .abbreviated, time: .shortened)
    }

    private var frequentStuckSentenceText: String {
        let indexes = histories.flatMap(\.stuckSentenceIndexes)
        guard let index = indexes.mostFrequentValue else { return "暂无" }
        return "第 \(index + 1) 句"
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            metric("完成次数", value: "\(histories.count)", systemImage: "checkmark.circle")
            metric("平均用时", value: VocabularyStudySessionFormat.duration(averageDuration), systemImage: "timer")
            metric("最近完成", value: lastCompletedText, systemImage: "calendar")
            metric("易卡句", value: frequentStuckSentenceText, systemImage: "exclamationmark.bubble")
        }
        .font(.callout)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.panelBackgroundColor, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(palette.borderColor.opacity(0.7), lineWidth: 1)
        }
    }

    private func metric(_ title: String, value: String, systemImage: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(palette.secondaryTextColor)
                Text(value)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(palette.primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(palette.accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct VocabularyArticleReadingTextView: View {
    let articleText: String
    let palette: PaperClipReadingPalette
    let onStartRecitation: () -> Void

    private var wordCount: Int {
        VocabularyArticleTextNormalizer.words(from: articleText).count
    }

    private var sentenceCount: Int {
        VocabularyArticleSentence.split(articleText).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("阅读")
                        .font(.headline)
                        .foregroundStyle(palette.primaryTextColor)
                    Text("\(sentenceCount) 句 · \(wordCount) 词")
                        .font(.caption)
                        .foregroundStyle(palette.secondaryTextColor)
                }

                Spacer(minLength: 12)

                Button("进入背诵", systemImage: "mic.circle") {
                    onStartRecitation()
                }
                .buttonStyle(.borderedProminent)
            }

            VocabularyArticleSelectableTextView(text: articleText, palette: palette)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 24)
        .background(palette.panelBackgroundColor, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(palette.borderColor.opacity(0.7), lineWidth: 1)
        }
    }
}

private struct VocabularyArticleSelectableTextView: UIViewRepresentable {
    let text: String
    let palette: PaperClipReadingPalette

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.adjustsFontForContentSizeCategory = true
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultLow, for: .vertical)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        textView.attributedText = attributedText
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width else { return nil }
        let size = uiView.sizeThatFits(
            CGSize(width: width, height: .greatestFiniteMagnitude)
        )
        return CGSize(width: width, height: size.height)
    }

    private var attributedText: NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 9
        paragraphStyle.paragraphSpacing = 12

        return NSAttributedString(
            string: text,
            attributes: [
                .font: Self.readingFont,
                .foregroundColor: palette.primaryText,
                .paragraphStyle: paragraphStyle
            ]
        )
    }

    private static var readingFont: UIFont {
        let descriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .title3)
            .withDesign(.serif) ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title3)
        let font = UIFont(descriptor: descriptor, size: 0)
        return UIFontMetrics(forTextStyle: .title3).scaledFont(for: font)
    }
}

private struct VocabularyArticleMaskedTextView: View {
    let sentences: [VocabularyArticleSentence]
    let revealedSentenceCount: Int
    let currentSentenceIndex: Int
    let currentWordIndex: Int
    let isComplete: Bool
    let palette: PaperClipReadingPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("背诵稿")
                    .font(.headline)
                    .foregroundStyle(palette.primaryTextColor)
                Spacer(minLength: 12)
                Text("\(sentences.count) 句")
                    .font(.caption)
                    .foregroundStyle(palette.secondaryTextColor)
            }

            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(sentences.indices, id: \.self) { index in
                    let isRevealed = index < revealedSentenceCount || isComplete
                    let isCurrent = index == currentSentenceIndex && !isComplete
                    let visiblePrefix = isCurrent
                        ? VocabularyArticleDisplayText.prefix(
                            sentences[index].text,
                            matchedWordCount: currentWordIndex
                        )
                        : ""

                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isCurrent ? .white : palette.secondaryTextColor)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(isCurrent ? palette.accentColor : palette.chipBackgroundColor)
                            )

                        VStack(alignment: .leading, spacing: 8) {
                            ZStack(alignment: .leading) {
                                Text(sentences[index].text)
                                    .font(.system(.title3, design: .serif))
                                    .lineSpacing(7)
                                    .foregroundStyle(isRevealed ? palette.primaryTextColor : palette.secondaryTextColor)
                                    .blur(radius: isRevealed ? 0 : 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if !isRevealed {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(palette.maskOverlayColor)
                                        .opacity(isCurrent ? 0.70 : 0.92)
                                }

                                if !visiblePrefix.isEmpty {
                                    Text(visiblePrefix)
                                        .font(.system(.title3, design: .serif))
                                        .lineSpacing(7)
                                        .foregroundStyle(palette.primaryTextColor)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }

                            if isCurrent, let currentSentence = sentences[safe: index], !currentSentence.words.isEmpty {
                                ProgressView(
                                    value: Double(currentWordIndex),
                                    total: Double(currentSentence.words.count)
                                )
                                .tint(palette.accentColor)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isCurrent ? palette.accentColor.opacity(0.10) : palette.rowBackgroundColor.opacity(0.70))
                    )
                    .overlay {
                        if isCurrent {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(palette.accentColor.opacity(0.40), lineWidth: 1)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 22)
        .background(palette.panelBackgroundColor, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(palette.borderColor.opacity(0.7), lineWidth: 1)
        }
    }
}

private extension Array where Element == Int {
    var mostFrequentValue: Element? {
        var counts: [Element: Int] = [:]
        for value in self {
            counts[value, default: 0] += 1
        }
        return counts.max { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key > rhs.key
            }
            return lhs.value < rhs.value
        }?.key
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
