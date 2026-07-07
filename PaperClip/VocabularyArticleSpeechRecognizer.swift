import AVFoundation
import Combine
import Foundation
import Speech

@MainActor
final class VocabularyArticleSpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var isStarting = false

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isTapInstalled = false
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

        let speechAuthorization = await VocabularyArticleSpeechPermissions.requestSpeechAuthorization()
        guard isCurrentStart(generation) else { return }
        guard speechAuthorization == .authorized else {
            throw VocabularyArticleSpeechError.speechNotAuthorized
        }

        let microphoneAllowed = await VocabularyArticleSpeechPermissions.requestMicrophonePermission()
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

        recognitionTask = VocabularyArticleSpeechRuntime.makeRecognitionTask(
            speechRecognizer: speechRecognizer,
            request: request
        ) { [weak self] transcript, shouldFinish in
            guard self?.isCurrentStart(generation) == true else { return }
            if let transcript {
                self?.transcript = transcript
            }
            if shouldFinish {
                self?.finishRecognition(cancelTask: false)
            }
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        VocabularyArticleSpeechRuntime.installAudioTap(
            on: inputNode,
            format: recordingFormat,
            request: request
        )
        isTapInstalled = true

        guard isCurrentStart(generation) else {
            finishRecognition(cancelTask: true)
            return
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            finishRecognition(cancelTask: true)
            throw error
        }

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

        if isTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }

        let request = recognitionRequest
        let task = recognitionTask
        recognitionRequest = nil
        recognitionTask = nil

        request?.endAudio()
        if cancelTask {
            task?.cancel()
        }
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func isCurrentStart(_ generation: Int) -> Bool {
        startGeneration == generation
    }
}

private enum VocabularyArticleSpeechPermissions {
    static func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    static func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { isAllowed in
                continuation.resume(returning: isAllowed)
            }
        }
    }
}

private enum VocabularyArticleSpeechRuntime {
    static func makeRecognitionTask(
        speechRecognizer: SFSpeechRecognizer,
        request: SFSpeechAudioBufferRecognitionRequest,
        onResult: @escaping @MainActor (String?, Bool) -> Void
    ) -> SFSpeechRecognitionTask {
        speechRecognizer.recognitionTask(with: request) { result, error in
            let transcript = result?.bestTranscription.formattedString
            let shouldFinish = error != nil || result?.isFinal == true
            Task { @MainActor in
                onResult(transcript, shouldFinish)
            }
        }
    }

    static func installAudioTap(
        on inputNode: AVAudioInputNode,
        format: AVAudioFormat,
        request: SFSpeechAudioBufferRecognitionRequest
    ) {
        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
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
