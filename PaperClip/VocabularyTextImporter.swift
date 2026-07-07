import Foundation

enum VocabularyTextImporter {
    static func parse(_ text: String, format requested: VocabularyTextFormat = .automatic) -> VocabularyImportResult {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let format = requested == .automatic ? detectFormat(normalized) : requested
        let rows: [VocabularyImportRow]

        switch format {
        case .json:
            rows = VocabularyTextParserSupport.parseJSON(normalized)
        case .pairedLines:
            rows = VocabularyTextParserSupport.parsePairedLines(normalized)
        case .markdown:
            rows = VocabularyTextParserSupport.parseDelimited(normalized, delimiter: "|", markdown: true)
        case .tab:
            rows = VocabularyTextParserSupport.parseDelimited(normalized, delimiter: "\t")
        case .pipe:
            rows = VocabularyTextParserSupport.parseDelimited(normalized, delimiter: "|")
        case .equals:
            rows = VocabularyTextParserSupport.parseDelimited(normalized, delimiter: "=")
        case .colon:
            rows = VocabularyTextParserSupport.parseColon(normalized)
        case .dash:
            rows = VocabularyTextParserSupport.parseDash(normalized)
        case .comma:
            rows = VocabularyTextParserSupport.parseCSV(normalized)
        case .automatic:
            rows = []
        }
        return VocabularyImportResult(format: format, rows: rows)
    }

    static func detectFormat(_ text: String) -> VocabularyTextFormat {
        VocabularyTextParserSupport.detectFormat(text)
    }
}
