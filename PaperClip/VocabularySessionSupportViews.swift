import SwiftUI
import PencilKit
import AVFoundation

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage

    init(_ image: UIImage) {
        self.image = image
    }
}

@MainActor
enum VocabularySpeech {
    private static let synthesizer = AVSpeechSynthesizer()

    static func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
}

struct VocabularyProgressHeader: View {
    let index: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(min(index + 1, total)) / \(total)")
                    .font(.subheadline.monospacedDigit())
                Spacer()
                Text("\(Int(Double(min(index, total)) / Double(max(1, total)) * 100))%")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(min(index, total)), total: Double(max(1, total)))
        }
    }
}

extension VocabularyReviewRating {
    var tint: Color {
        switch self {
        case .again: .red
        case .hard: .orange
        case .good: .green
        case .easy: .blue
        }
    }
}

enum VocabularyFlashcardDragAxis {
    case undecided
    case horizontal
    case vertical
}

struct VocabularyFlashcardDragState {
    var axis = VocabularyFlashcardDragAxis.undecided
    var translation = CGSize.zero

    static let inactive = VocabularyFlashcardDragState()
}

struct VocabularySessionCompleteView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

enum VocabularyStudyKind: Int, CaseIterable {
    case choice
    case spelling
    case listening
    case handwriting

    var title: String {
        switch self {
        case .choice: "拼句"
        case .spelling: "拼写"
        case .listening: "听写"
        case .handwriting: "手写"
        }
    }
}
