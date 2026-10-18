import Foundation

enum VocabularyTextImporter {
    static func parse(_ text: String, format: VocabularyTextFormat) -> VocabularyImportResult {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let rows: [VocabularyImportRow]

        switch format {
        case .pairedLines:
            rows = VocabularyPairedLineTextParser.parse(normalized)
        case .tab:
            rows = VocabularyDelimitedTextParser.parse(normalized, delimiter: "\t")
        case .comma:
            rows = VocabularyDelimitedTextParser.parseCSV(normalized)
        }
        return VocabularyImportResult(format: format, rows: rows)
    }
}
