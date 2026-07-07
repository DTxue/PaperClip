import Foundation

enum VocabularyPairedLineTextParser {
    static func parse(_ text: String) -> [VocabularyImportRow] {
        let blocks = text.components(separatedBy: blockSeparator)
        if blocks.count > 1 {
            return blocks.enumerated().map { index, block in
                VocabularyTextRowBuilder.makeRow(
                    index: index,
                    fields: trimmedLines(in: block)
                )
            }
        }

        let lines = trimmedLines(in: text)
        return stride(from: 0, to: lines.count, by: 2).enumerated().map { index, offset in
            let end = min(offset + 2, lines.count)
            return VocabularyTextRowBuilder.makeRow(
                index: index,
                fields: Array(lines[offset..<end])
            )
        }
    }

    private static func trimmedLines(in text: String) -> [String] {
        text.split(separator: "\n", omittingEmptySubsequences: true).map {
            String($0).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private static let blockSeparator = try! NSRegularExpression(
        pattern: #"\n\s*\n"#
    )
}
