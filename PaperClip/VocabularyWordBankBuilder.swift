import Foundation

enum VocabularyWordBankBuilder {
    static func sentenceTiles(_ sentence: String) -> [String] {
        sentence.split(whereSeparator: \.isWhitespace).map(String.init)
    }

    static func build(
        correctTiles: [String],
        distractorTiles: [String],
        maximumDistractorCount: Int = 5
    ) -> [VocabularyWordBankTile] {
        let correctItems = trimmed(correctTiles).enumerated().map {
            VocabularyWordBankTile(id: $0.offset, text: $0.element)
        }
        let distractorItems = normalized(distractorTiles)
            .filter { tile in !correctItems.contains { $0.text == tile } }
            .prefix(max(0, maximumDistractorCount))
            .enumerated()
            .map {
                VocabularyWordBankTile(id: $0.offset + 1000, text: $0.element)
            }

        return correctItems + distractorItems
    }

    static func sampleDistractorTerms(
        candidates: [VocabularyCard],
        excluding card: VocabularyCard,
        limit: Int
    ) -> [String] {
        guard limit > 0 else { return [] }
        var sample: [String] = []
        sample.reserveCapacity(limit)
        var candidateCount = 0

        for candidate in candidates where candidate.id != card.id {
            let term = candidate.term.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !term.isEmpty, term != card.term else { continue }
            candidateCount += 1
            if sample.count < limit {
                sample.append(term)
                continue
            }
            let replacementIndex = Int.random(in: 0 ..< candidateCount)
            if replacementIndex < limit {
                sample[replacementIndex] = term
            }
        }
        return sample.shuffled()
    }

    private static func normalized(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        return trimmed(values).filter { value in
            seen.insert(value).inserted
        }
    }

    private static func trimmed(_ values: [String]) -> [String] {
        values.compactMap { value in
            let result = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return result.isEmpty ? nil : result
        }
    }
}
