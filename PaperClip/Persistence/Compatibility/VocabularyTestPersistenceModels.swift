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

// Dormant draft records remain in V1–V5 for existing stores and explicit deck deletion.
// Current quizzes do not create or restore these records.
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

}
}

typealias VocabularyTestDraft = PaperClipSchemaV1.VocabularyTestDraft
