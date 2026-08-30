import Foundation
import SwiftData

struct VocabularyTestDraftBatchSnapshot: Codable {
    var id: Int
    var startIndex: Int
    var cardIDs: [UUID]
    var drawingsData: [Data]
    var status: String
    var gradingAttempts: Int
    var result: VocabularyGradingResult?
    var errorMessage: String?
}

struct VocabularyTestDraftSavePayload {
    let batchSize: Int
    let currentBatchIndex: Int
    let currentQuestionIndex: Int
    let currentDrawingData: Data
    let didFinishAnswering: Bool
    let startedAt: Date
    let batches: [VocabularyTestDraftBatchSnapshot]
}

extension PaperClipSchemaV1 {
@Model
final class VocabularyTestDraft {
    static var deletionPropertiesToFetch: [PartialKeyPath<VocabularyTestDraft>] {
        [\.id]
    }

    @Attribute(.unique) var id: UUID
    var deckID: UUID
    var mode: String
    var batchSize: Int
    var currentBatchIndex: Int
    var currentQuestionIndex: Int
    @Attribute(.externalStorage) var currentDrawingData: Data
    var didFinishAnswering: Bool
    var startedAt: Date
    var updatedAt: Date
    var batchesJSON: String

    init(
        id: UUID = UUID(),
        deckID: UUID,
        mode: String,
        payload: VocabularyTestDraftSavePayload,
        updatedAt: Date = .now,
    ) {
        self.id = id
        self.deckID = deckID
        self.mode = mode
        self.batchSize = payload.batchSize
        self.currentBatchIndex = payload.currentBatchIndex
        self.currentQuestionIndex = payload.currentQuestionIndex
        self.currentDrawingData = payload.currentDrawingData
        self.didFinishAnswering = payload.didFinishAnswering
        self.startedAt = payload.startedAt
        self.updatedAt = updatedAt
        self.batchesJSON = VocabularyJSONStorage.encode(payload.batches)
    }

    var batches: [VocabularyTestDraftBatchSnapshot] {
        VocabularyJSONStorage.decode(
            [VocabularyTestDraftBatchSnapshot].self,
            from: batchesJSON,
            fallback: []
        )
    }

    @discardableResult
    func update(payload: VocabularyTestDraftSavePayload) -> Bool {
        let nextBatchesJSON = VocabularyJSONStorage.encode(payload.batches)
        let hasChanges = self.batchSize != payload.batchSize
            || self.currentBatchIndex != payload.currentBatchIndex
            || self.currentQuestionIndex != payload.currentQuestionIndex
            || self.currentDrawingData != payload.currentDrawingData
            || self.didFinishAnswering != payload.didFinishAnswering
            || self.startedAt != payload.startedAt
            || self.batchesJSON != nextBatchesJSON

        guard hasChanges else { return false }

        self.batchSize = payload.batchSize
        self.currentBatchIndex = payload.currentBatchIndex
        self.currentQuestionIndex = payload.currentQuestionIndex
        self.currentDrawingData = payload.currentDrawingData
        self.didFinishAnswering = payload.didFinishAnswering
        self.startedAt = payload.startedAt
        self.updatedAt = .now
        self.batchesJSON = nextBatchesJSON
        return true
    }

}
}

typealias VocabularyTestDraft = PaperClipSchemaV1.VocabularyTestDraft
