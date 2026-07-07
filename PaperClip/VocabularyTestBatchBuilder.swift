import Foundation

enum VocabularyTestBatchBuilder {
    static func makeBatches(from cards: [VocabularyCard], batchSize: Int) -> [VocabularyTestBatch] {
        let safeBatchSize = max(1, batchSize)
        return stride(from: 0, to: cards.count, by: safeBatchSize).enumerated().map { batchID, start in
            let end = min(start + safeBatchSize, cards.count)
            return VocabularyTestBatch(
                id: batchID,
                startIndex: start,
                cards: Array(cards[start ..< end])
            )
        }
    }

    static func maximumQuestionCount(in batches: [VocabularyTestBatch]) -> Int {
        VocabularyTestQuestionCount.maximum(inBatchCardCounts: batches.map { $0.cards.count })
    }
}
