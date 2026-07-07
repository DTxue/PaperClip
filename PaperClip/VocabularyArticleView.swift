import AVFoundation
import Speech
import SwiftData
import SwiftUI

struct VocabularyArticleView: View {
    let deck: VocabularyDeck

    @Environment(\.modelContext) private var modelContext
    @StateObject private var speechRecognizer = VocabularyArticleSpeechRecognizer()
    @State private var cards: [VocabularyCard] = []
    @State private var article: VocabularyGeneratedArticle?
    @State private var recitation = VocabularyArticleRecitationState(sentences: [])
    @State private var viewMode: VocabularyArticleViewMode = .reading
    @State private var processedSpeechWordCount = 0
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
                    recitationControls

                    VocabularyArticleMaskedTextView(
                        sentences: recitation.sentences,
                        revealedSentenceCount: recitation.revealedSentenceCount,
                        currentSentenceIndex: recitation.currentSentenceIndex,
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
                    processedSpeechWordCount = 0
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
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func loadData() {
        do {
            cards = try modelContext.fetchVocabularyArticleCards(deckID: deck.id)
            article = try modelContext.fetchVocabularyGeneratedArticle(deckID: deck.id)
            resetRecitation()
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
            viewMode = .reading
        } catch {
            alert = AppAlert(title: "无法生成词生文", error: error)
        }
    }

    private func resetRecitation() {
        speechRecognizer.stop()
        processedSpeechWordCount = 0
        recitation = VocabularyArticleRecitationState(
            sentences: VocabularyArticleSentence.split(article?.articleText ?? "")
        )
    }

    private func startListening() async {
        guard !speechRecognizer.isRecording, !speechRecognizer.isStarting else { return }
        do {
            processedSpeechWordCount = 0
            try await speechRecognizer.start()
        } catch {
            alert = AppAlert(title: "无法开始语音识别", error: error)
        }
    }

    private func processTranscript(_ transcript: String) {
        let words = VocabularyArticleTextNormalizer.words(from: transcript)
        guard words.count >= processedSpeechWordCount else {
            processedSpeechWordCount = words.count
            return
        }

        let newWords = Array(words.dropFirst(processedSpeechWordCount))
        processedSpeechWordCount = words.count
        guard !newWords.isEmpty else { return }

        recitation.process(words: newWords)
        if recitation.isComplete {
            speechRecognizer.stop()
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
    let isComplete: Bool

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 10) {
            ForEach(sentences.indices, id: \.self) { index in
                let isRevealed = index < revealedSentenceCount || isComplete
                let isCurrent = index == currentSentenceIndex && !isComplete

                Text(sentences[index].text)
                    .font(.title3)
                    .lineSpacing(5)
                    .foregroundStyle(isRevealed ? .primary : .secondary)
                    .blur(radius: isRevealed ? 0 : 4)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isCurrent ? Color.accentColor.opacity(0.08) : Color.clear)
                    )
                    .overlay {
                        if !isRevealed {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.regularMaterial)
                                .opacity(isCurrent ? 0.72 : 0.92)
                        }
                    }
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

@MainActor
final class VocabularyArticleSpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var isStarting = false

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var startGeneration = 0

    func start() async throws {
        guard !isStarting, !isRecording else { return }
        startGeneration += 1
        let generation = startGeneration
        isStarting = true
        defer {
            if self.startGeneration == generation {
                self.isStarting = false
            }
        }

        finishRecognition(cancelTask: true)
        transcript = ""

        let speechAuthorization = await requestSpeechAuthorization()
        guard isCurrentStart(generation) else { return }
        guard speechAuthorization == .authorized else {
            throw VocabularyArticleSpeechError.speechNotAuthorized
        }

        let microphoneAllowed = await requestMicrophonePermission()
        guard isCurrentStart(generation) else { return }
        guard microphoneAllowed else {
            throw VocabularyArticleSpeechError.microphoneNotAuthorized
        }

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw VocabularyArticleSpeechError.recognizerUnavailable
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        guard isCurrentStart(generation) else {
            finishRecognition(cancelTask: true)
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard self?.isCurrentStart(generation) == true else { return }
                if let result {
                    self?.transcript = result.bestTranscription.formattedString
                }
                if error != nil || result?.isFinal == true {
                    self?.finishRecognition(cancelTask: false)
                }
            }
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: recordingFormat) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        guard isCurrentStart(generation) else {
            finishRecognition(cancelTask: true)
            return
        }

        audioEngine.prepare()
        try audioEngine.start()
        guard isCurrentStart(generation) else {
            finishRecognition(cancelTask: true)
            return
        }
        isRecording = true
    }

    func stop() {
        startGeneration += 1
        isStarting = false
        guard isRecording || recognitionTask != nil || recognitionRequest != nil else { return }
        finishRecognition(cancelTask: true)
    }

    private func finishRecognition(cancelTask: Bool) {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        if cancelTask {
            recognitionTask?.cancel()
        }
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func isCurrentStart(_ generation: Int) -> Bool {
        startGeneration == generation
    }

    private func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { isAllowed in
                continuation.resume(returning: isAllowed)
            }
        }
    }
}

private enum VocabularyArticleSpeechError: LocalizedError {
    case speechNotAuthorized
    case microphoneNotAuthorized
    case recognizerUnavailable

    var errorDescription: String? {
        switch self {
        case .speechNotAuthorized:
            "请在系统设置中允许 PaperClip 使用语音识别。"
        case .microphoneNotAuthorized:
            "请在系统设置中允许 PaperClip 使用麦克风。"
        case .recognizerUnavailable:
            "当前设备暂时无法使用英语语音识别。"
        }
    }
}
