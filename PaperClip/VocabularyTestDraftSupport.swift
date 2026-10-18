import PencilKit
import UIKit

enum VocabularyTestBatchStatus: String, Equatable {
    case answering
    case grading
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
    var result: VocabularyGradingResult?
    var errorMessage: String?

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
    let gradedQuestions: [VocabularyGradedQuestion]
    let maximumQuestionCount: Int

    init(
        deckCards: [VocabularyCard],
        batches: [VocabularyTestBatch]
    ) {
        self.deckCards = deckCards

        gradedQuestions = VocabularyTestBatchProjection.gradedQuestions(from: batches)
        maximumQuestionCount = VocabularyTestQuestionCount.clamped(deckCards.count)
    }
}
