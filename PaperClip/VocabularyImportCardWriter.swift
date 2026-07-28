import Foundation
import SwiftData

struct VocabularyImportWriteResult {
    var imported: Int = 0
    var skipped: Int = 0
}

enum VocabularyImportCardWriter {
    static func insertCards(
        _ rows: [VocabularyImportRow],
        deckID: UUID,
        kind: VocabularyDeckKind = .word,
        in modelContext: ModelContext
    ) {
        for row in rows {
            modelContext.insert(makeCard(from: row, deckID: deckID, kind: kind))
        }
    }

    static func importRows(
        _ rows: [VocabularyImportRow],
        into deck: VocabularyDeck,
        in modelContext: ModelContext,
        duplicateStrategy: VocabularyDuplicateStrategy
    ) throws -> VocabularyImportWriteResult {
        var lookup = try existingCardLookup(deckID: deck.id, in: modelContext)
        var result = VocabularyImportWriteResult()

        for row in rows {
            let key = VocabularyAnswerChecker.normalize(row.term)
            if let duplicate = lookup[key] {
                switch duplicateStrategy {
                case .skip:
                    result.skipped += 1
                    continue
                case .merge:
                    mergeMissingFields(from: row, into: duplicate, kind: deck.kind)
                    result.skipped += 1
                    continue
                case .duplicate:
                    break
                }
            }

            let card = makeCard(from: row, deckID: deck.id, kind: deck.kind)
            modelContext.insert(card)
            if duplicateStrategy != .duplicate { lookup[key] = card }
            result.imported += 1
        }

        return result
    }

    private static func existingCardLookup(
        deckID: UUID,
        in modelContext: ModelContext
    ) throws -> [String: VocabularyCard] {
        let existingCards = try modelContext.fetchVocabularyCards(
            deckID: deckID,
            propertiesToFetch: VocabularyCard.importMergePropertiesToFetch
        )
        return Dictionary(
            existingCards.map { (VocabularyAnswerChecker.normalize($0.term), $0) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    private static func makeCard(
        from row: VocabularyImportRow,
        deckID: UUID,
        kind: VocabularyDeckKind
    ) -> VocabularyCard {
        VocabularyCard(
            deckID: deckID,
            term: row.term,
            definition: row.definition,
            phonetic: kind.usesWordSpecificFeatures ? row.phonetic : "",
            example: kind.usesWordSpecificFeatures ? row.example : "",
            partOfSpeech: kind.usesWordSpecificFeatures ? row.partOfSpeech : "",
            tagsText: row.tags,
            note: row.note,
            alternativeAnswersText: row.alternatives
        )
    }

    private static func mergeMissingFields(
        from row: VocabularyImportRow,
        into card: VocabularyCard,
        kind: VocabularyDeckKind
    ) {
        if kind.usesWordSpecificFeatures {
            if card.phonetic.isEmpty { card.phonetic = row.phonetic }
            if card.example.isEmpty { card.example = row.example }
            if card.partOfSpeech.isEmpty { card.partOfSpeech = row.partOfSpeech }
        }
        if card.tagsText.isEmpty { card.tagsText = row.tags }
        if card.note.isEmpty { card.note = row.note }
        if card.alternativeAnswersText.isEmpty { card.alternativeAnswersText = row.alternatives }
    }
}
