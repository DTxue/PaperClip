import Foundation
import SwiftData
import SwiftUI

struct VocabularyArticleView: View {
    let deck: VocabularyDeck

    @Environment(\.modelContext) private var modelContext
    @StateObject private var speechRecognizer = VocabularyArticleSpeechRecognizer()
    @State private var cards: [VocabularyCard] = []
    @State private var article: VocabularyGeneratedArticle?
    @State private var recitation = VocabularyArticleRecitationState(sentences: [])
    @State private var recitationHistories: [VocabularyArticleRecitationHistory] = []
    @State private var viewMode: VocabularyArticleViewMode = .reading
    @State private var listeningBaseline: VocabularyArticleRecitationState?
    @State private var sessionStartedAt: Date?
    @State private var stuckSentenceIndexes: Set<Int> = []
    @State private var completionFeedbackTick = 0
    @State private var isGenerating = false
    @State private var alert: AppAlert?

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
                    Text("使用当前词集中所有内容生成一篇适合背诵的英文文章。")
                } actions: {
                    Button("生成词生文", systemImage: "wand.and.stars") {
                        Task { await generateArticle() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isGenerating)
                }
            }
        }
        .overlay {
            if isGenerating {
                ProgressView("正在生成词生文...")
                    .padding(20)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if article != nil {
                    Button("重新生成", systemImage: "arrow.triangle.2.circlepath") {
                        Task { await generateArticle() }
                    }
                    .disabled(isGenerating)
                }
            }
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
            speechRecognizer.stop()
        }
        .sensoryFeedback(.success, trigger: completionFeedbackTick)
    }

    private func articleContent(_ article: VocabularyGeneratedArticle) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(article.title)
                        .font(.title2.weight(.semibold))
                    Text("由 \(article.modelName) 生成 · \(cards.count) 个词条")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Picker("词生文模式", selection: $viewMode) {
                    ForEach(VocabularyArticleViewMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.systemImage)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if viewMode == .reading {
                    VocabularyArticleReadingTextView(articleText: article.articleText) {
                        viewMode = .recitation
                    }
                } else {
                    VocabularyArticleRecitationSummaryView(histories: recitationHistories)

                    recitationControls

                    VocabularyArticleMaskedTextView(
                        sentences: recitation.sentences,
                        revealedSentenceCount: recitation.revealedSentenceCount,
                        currentSentenceIndex: recitation.currentSentenceIndex,
                        currentWordIndex: recitation.currentWordIndex,
                        isComplete: recitation.isComplete
                    )

                    if let mismatch = recitation.lastMismatchWord {
                        Label("检测到不匹配：\(mismatch)。请从当前句开头重新背诵。", systemImage: "exclamationmark.triangle")
                            .font(.callout)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 900, alignment: .leading)
        }
    }

    private var recitationControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
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

            HStack(spacing: 14) {
                Label(
                    recitation.isComplete ? "已完成" : "第 \(min(recitation.currentSentenceIndex + 1, recitation.sentences.count))/\(recitation.sentences.count) 句",
                    systemImage: recitation.isComplete ? "checkmark.circle.fill" : "text.alignleft"
                )
                Label(recitation.currentProgressText, systemImage: "waveform")
                if speechRecognizer.isRecording {
                    Label("正在听写", systemImage: "mic.fill")
                        .foregroundStyle(.blue)
                }
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            if speechRecognizer.isRecording || !speechRecognizer.transcript.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("识别文本")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(speechRecognizer.transcript.isEmpty ? "..." : speechRecognizer.transcript)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func loadData() {
        do {
            cards = try modelContext.fetchVocabularyArticleCards(deckID: deck.id)
            article = try modelContext.fetchVocabularyGeneratedArticle(deckID: deck.id)
            resetRecitation()
            loadRecitationHistories()
        } catch {
            alert = AppAlert(title: "无法读取词生文", error: error)
        }
    }

    private func generateArticle() async {
        do {
            isGenerating = true
            defer { isGenerating = false }

            let latestCards = try modelContext.fetchVocabularyArticleCards(deckID: deck.id)
            guard !latestCards.isEmpty else {
                cards = []
                article = nil
                return
            }

            let inputs = latestCards.map { VocabularyArticleCardInput(card: $0) }
            let draft = try await AIService.generateVocabularyArticle(cards: inputs)
            let storedArticle = try modelContext.upsertVocabularyGeneratedArticle(
                deckID: deck.id,
                draft: draft
            )
            try modelContext.save()
            cards = latestCards
            article = storedArticle
            resetRecitation()
            loadRecitationHistories()
            viewMode = .reading
        } catch {
            alert = AppAlert(title: "无法生成词生文", error: error)
        }
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
                deckID: deck.id,
                articleSnapshotHash: article.sourceCardSnapshotHash
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

private enum VocabularyArticleViewMode: String, CaseIterable, Identifiable {
    case reading
    case recitation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reading: "阅读"
        case .recitation: "背诵"
        }
    }

    var systemImage: String {
        switch self {
        case .reading: "text.book.closed"
        case .recitation: "mic.circle"
        }
    }
}

private struct VocabularyArticleRecitationSummaryView: View {
    let histories: [VocabularyArticleRecitationHistory]

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
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func metric(_ title: String, value: String, systemImage: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct VocabularyArticleReadingTextView: View {
    let articleText: String
    let onStartRecitation: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(articleText)
                .font(.title3)
                .lineSpacing(7)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("进入背诵", systemImage: "mic.circle") {
                onStartRecitation()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct VocabularyArticleMaskedTextView: View {
    let sentences: [VocabularyArticleSentence]
    let revealedSentenceCount: Int
    let currentSentenceIndex: Int
    let currentWordIndex: Int
    let isComplete: Bool

    var body: some View {
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

                VStack(alignment: .leading, spacing: 6) {
                    ZStack(alignment: .leading) {
                        Text(sentences[index].text)
                            .font(.title3)
                            .lineSpacing(5)
                            .foregroundStyle(isRevealed ? .primary : .secondary)
                            .blur(radius: isRevealed ? 0 : 4)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if !isRevealed {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.regularMaterial)
                                .opacity(isCurrent ? 0.72 : 0.92)
                        }

                        if !visiblePrefix.isEmpty {
                            Text(visiblePrefix)
                                .font(.title3)
                                .lineSpacing(5)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    if isCurrent, let currentSentence = sentences[safe: index], !currentSentence.words.isEmpty {
                        ProgressView(
                            value: Double(currentWordIndex),
                            total: Double(currentSentence.words.count)
                        )
                        .tint(.blue)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isCurrent ? Color.accentColor.opacity(0.08) : Color.clear)
                )
                .overlay {
                    if isCurrent {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor.opacity(0.35), lineWidth: 1)
                    }
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
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
