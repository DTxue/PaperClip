import Foundation
import SwiftData

enum VocabularyImportOperations {
    @discardableResult
    static func createDeck(
        in modelContext: ModelContext,
        kind: VocabularyDeckKind = .word,
        title: String,
        dailyNewLimit: Int,
        desiredRetention: Double,
        sourceName: String,
        preset: VocabularyImportPreset,
        importResult: VocabularyImportResult
    ) throws -> VocabularyDeck {
        let projection = importResult.projection
        let deck = VocabularyDeck(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            dailyNewLimit: dailyNewLimit,
            desiredRetention: desiredRetention
        )
        deck.kind = kind
        modelContext.insert(deck)
        VocabularyImportCardWriter.insertCards(
            projection.validRows,
            deckID: deck.id,
            kind: kind,
            in: modelContext
        )
        modelContext.insert(VocabularyImportBatch(
            deckID: deck.id,
            sourceName: sourceName,
            detectedFormat: preset.format.rawValue,
            importedCount: projection.summary.validCount,
            skippedCount: 0,
            failedCount: projection.summary.failedCount
        ))
        try modelContext.saveOrRollbackIfNeeded()
        return deck
    }

    static func importRows(
        into deck: VocabularyDeck,
        in modelContext: ModelContext,
        sourceName: String,
        preset: VocabularyImportPreset,
        duplicateStrategy: VocabularyDuplicateStrategy,
        importResult: VocabularyImportResult
    ) throws {
        let projection = importResult.projection
        let writeResult = try VocabularyImportCardWriter.importRows(
            projection.validRows,
            into: deck,
            in: modelContext,
            duplicateStrategy: duplicateStrategy
        )

        modelContext.insert(VocabularyImportBatch(
            deckID: deck.id,
            sourceName: sourceName,
            detectedFormat: preset.format.rawValue,
            importedCount: writeResult.imported,
            skippedCount: writeResult.skipped,
            failedCount: projection.summary.failedCount
        ))
        deck.updatedAt = .now
        try modelContext.saveOrRollbackIfNeeded()
    }
}
