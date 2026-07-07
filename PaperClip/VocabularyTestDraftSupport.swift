import PencilKit
import UIKit

enum VocabularyTestMode: String, CaseIterable, Identifiable {
    case regular = "常规"
    case exam = "考试"

    var id: String { rawValue }
}

enum VocabularyTestBatchStatus: String, Equatable {
    case answering
    case grading
    case retrying
    case graded
    case failed
}

struct VocabularyTestBatch: Identifiable {
    let id: Int
    let startIndex: Int
    var cards: [VocabularyCard]
    var drawings: [PKDrawing] = []
    var renderedImages: [UIImage?] = []
    var status: VocabularyTestBatchStatus = .answering
    var gradingAttempts = 0
    var result: VocabularyGradingResult?
    var errorMessage: String?

    var endIndex: Int {
        startIndex + cards.count - 1
    }
}

struct VocabularyGradedQuestion: Identifiable {
    let globalIndex: Int
    let card: VocabularyCard
    let drawing: PKDrawing
    let image: UIImage?
    let item: VocabularyGradingItem?

    var id: UUID { card.id }
}

struct VocabularyTestViewSnapshot {
    let deckCards: [VocabularyCard]
    let deckDraft: VocabularyTestDraft?
    let gradedQuestions: [VocabularyGradedQuestion]
    let gradedBatchCount: Int
    let failedBatchIndices: [Int]
    let hasPendingGrading: Bool
    let maximumQuestionCount: Int

    init(
        deckCards: [VocabularyCard],
        deckDraft: VocabularyTestDraft?,
        batches: [VocabularyTestBatch]
    ) {
        self.deckCards = deckCards
        self.deckDraft = deckDraft

        var questions: [VocabularyGradedQuestion] = []
        var gradedCount = 0
        var failedIndices: [Int] = []
        var pending = false
        for batchIndex in batches.indices {
            let batch = batches[batchIndex]
            switch batch.status {
            case .graded:
                gradedCount += 1
            case .failed:
                failedIndices.append(batchIndex)
            case .grading, .retrying:
                pending = true
            case .answering:
                break
            }
            questions.append(contentsOf: VocabularyTestBatchProjection.makeGradedQuestions(from: batch))
        }
        gradedQuestions = questions
        gradedBatchCount = gradedCount
        failedBatchIndices = failedIndices
        hasPendingGrading = pending
        maximumQuestionCount = VocabularyTestQuestionCount.clamped(deckCards.count)
    }
}
