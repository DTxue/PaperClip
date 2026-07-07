import Foundation
import SwiftData

@Model
final class VocabularyImportBatch {
    static var deletionPropertiesToFetch: [PartialKeyPath<VocabularyImportBatch>] {
        [\.id]
    }

    @Attribute(.unique) var id: UUID
    var deckID: UUID
    var sourceName: String
    var detectedFormat: String
    var importedCount: Int
    var skippedCount: Int
    var failedCount: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        deckID: UUID,
        sourceName: String,
        detectedFormat: String,
        importedCount: Int,
        skippedCount: Int,
        failedCount: Int,
        createdAt: Date = .now
    ) {
        self.id = id
        self.deckID = deckID
        self.sourceName = sourceName
        self.detectedFormat = detectedFormat
        self.importedCount = importedCount
        self.skippedCount = skippedCount
        self.failedCount = failedCount
        self.createdAt = createdAt
    }
}
