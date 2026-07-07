import Foundation
import SwiftData

enum VocabularyImportOperations {
    static func createDeck(
        in modelContext: ModelContext,
        title: String,
        dailyNewLimit: Int,
        desiredRetention: Double,
        sourceName: String,
        preset: VocabularyImportPreset,
        importResult: VocabularyImportResult
    ) throws {
        let projection = importResult.projection
        let deck = VocabularyDeck(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            dailyNewLimit: dailyNewLimit,
            desiredRetention: desiredRetention
        )
        modelContext.insert(deck)
        VocabularyImportCardWriter.insertCards(
            projection.validRows,
            deckID: deck.id,
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
