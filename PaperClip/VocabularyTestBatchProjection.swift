import Foundation
import PencilKit

enum VocabularyTestBatchProjection {
    static func gradingItemsByIndex(for batch: VocabularyTestBatch) -> [Int: VocabularyGradingItem] {
        var itemByIndex: [Int: VocabularyGradingItem] = [:]
        for item in batch.result?.items ?? [] where itemByIndex[item.index] == nil {
            itemByIndex[item.index] = item
        }
        return itemByIndex
    }

    static func gradedQuestions(from batches: [VocabularyTestBatch]) -> [VocabularyGradedQuestion] {
        var questions: [VocabularyGradedQuestion] = []
        for batch in batches {
            questions.append(contentsOf: makeGradedQuestions(from: batch))
        }
        return questions
    }

    static func makeGradedQuestions(from batch: VocabularyTestBatch) -> [VocabularyGradedQuestion] {
        let itemByIndex = gradingItemsByIndex(for: batch)

        var questions: [VocabularyGradedQuestion] = []
        questions.reserveCapacity(batch.cards.count)
        for localIndex in batch.cards.indices {
            questions.append(
                VocabularyGradedQuestion(
                    globalIndex: batch.startIndex + localIndex,
                    card: batch.cards[localIndex],
                    drawing: batch.drawings.indices.contains(localIndex) ? batch.drawings[localIndex] : PKDrawing(),
                    image: batch.renderedImages.indices.contains(localIndex) ? batch.renderedImages[localIndex] : nil,
                    item: itemByIndex[localIndex + 1]
                )
            )
        }
        return questions
    }
}
