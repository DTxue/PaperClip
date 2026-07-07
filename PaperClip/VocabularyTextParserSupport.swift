import Foundation

enum VocabularyTextParserSupport {
    static func detectFormat(_ text: String) -> VocabularyTextFormat {
        VocabularyTextFormatDetector.detectFormat(text)
    }

    static func parseDelimited(
        _ text: String,
        delimiter: Character,
        markdown: Bool = false
    ) -> [VocabularyImportRow] {
        VocabularyDelimitedTextParser.parse(
            text,
            delimiter: delimiter,
            markdown: markdown
        )
    }

    static func parseDash(_ text: String) -> [VocabularyImportRow] {
        VocabularyDelimitedTextParser.parseDash(text)
    }

    static func parseColon(_ text: String) -> [VocabularyImportRow] {
        VocabularyDelimitedTextParser.parseColon(text)
    }

    static func parsePairedLines(_ text: String) -> [VocabularyImportRow] {
        VocabularyPairedLineTextParser.parse(text)
    }

    static func parseCSV(_ text: String) -> [VocabularyImportRow] {
        VocabularyDelimitedTextParser.parseCSV(text)
    }

    static func parseJSON(_ text: String) -> [VocabularyImportRow] {
        VocabularyJSONTextParser.parse(text)
    }
}
