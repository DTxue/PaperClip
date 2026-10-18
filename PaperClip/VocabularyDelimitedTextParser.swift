import Foundation

enum VocabularyDelimitedTextParser {
    static func parse(
        _ text: String,
        delimiter: Character
    ) -> [VocabularyImportRow] {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)

        return lines.enumerated().map { index, line in
            VocabularyTextRowBuilder.makeRow(
                index: index,
                fields: VocabularyTextRowBuilder.split(
                    line,
                    delimiter: delimiter
                )
            )
        }
    }

    static func parseCSV(_ text: String) -> [VocabularyImportRow] {
        text.split(separator: "\n", omittingEmptySubsequences: true).enumerated().map { index, line in
            VocabularyTextRowBuilder.makeRow(
                index: index,
                fields: VocabularyTextRowBuilder.csvFields(String(line))
            )
        }
    }

}
