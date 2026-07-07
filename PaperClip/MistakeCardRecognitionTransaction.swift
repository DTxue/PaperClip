import Foundation
import SwiftData

enum MistakeCardRecognitionTransaction {
    static func markPending(_ card: MistakeCard, in context: ModelContext) throws {
        card.recognitionStatus = RecognitionStatus.pending.rawValue
        card.updatedAt = .now
        try context.saveOrRollbackIfNeeded()
    }

    static func markProcessing(_ card: MistakeCard, in context: ModelContext) throws {
        card.recognitionStatus = RecognitionStatus.processing.rawValue
        card.updatedAt = .now
        try context.saveOrRollbackIfNeeded()
    }

    static func markFailed(_ card: MistakeCard, in context: ModelContext) throws {
        card.recognitionStatus = RecognitionStatus.failed.rawValue
        card.updatedAt = .now
        try context.saveOrRollbackIfNeeded()
    }

    static func markCompleted(
        _ card: MistakeCard,
        recognition: AIQuestionRecognition,
        in context: ModelContext
    ) throws {
        card.applyRecognition(recognition)
        card.recognitionStatus = RecognitionStatus.completed.rawValue
        card.updatedAt = .now
        try context.saveOrRollbackIfNeeded()
    }

    static func resetForRecovery(
        _ cards: [MistakeCard],
        in context: ModelContext
    ) throws {
        for card in cards {
            let status = MistakeRecognitionStatusSupport.recoveryStatus(from: card.recognitionStatus)
            if card.recognitionStatus != status {
                card.recognitionStatus = status
                card.updatedAt = .now
            }
        }
        try context.saveOrRollbackIfNeeded()
    }
}
