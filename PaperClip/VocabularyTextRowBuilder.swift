import Foundation

enum VocabularyTextRowBuilder {
    static func split(_ line: String, delimiter: Character) -> [String] {
        line.split(separator: delimiter, omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    static func csvFields(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var quoted = false
        var index = line.startIndex

        while index < line.endIndex {
            let character = line[index]
            if character == "\"" {
                let next = line.index(after: index)
                if quoted, next < line.endIndex, line[next] == "\"" {
                    current.append("\"")
                    index = next
                } else {
                    quoted.toggle()
                }
            } else if character == ",", !quoted {
                fields.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(character)
            }
            index = line.index(after: index)
        }

        fields.append(current.trimmingCharacters(in: .whitespaces))
        return fields
    }

    static func makeRow(index: Int, fields: [String]) -> VocabularyImportRow {
        let values = fields.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let term = values[safe: 0] ?? ""
        let definition = values[safe: 1] ?? ""
        return makeRow(
            id: index,
            term: term,
            definition: definition,
            phonetic: values[safe: 2] ?? "",
            example: values[safe: 3] ?? "",
            partOfSpeech: values[safe: 4] ?? "",
            tags: values[safe: 5] ?? "",
            note: values[safe: 6] ?? "",
            alternatives: values[safe: 7] ?? "",
            error: term.isEmpty || definition.isEmpty ? "单词和释义不能为空" : nil
        )
    }

    static func makeRow(
        id: Int,
        term: String,
        definition: String,
        phonetic: String = "",
        example: String = "",
        partOfSpeech: String = "",
        tags: String = "",
        note: String = "",
        alternatives: String = "",
        error: String? = nil
    ) -> VocabularyImportRow {
        VocabularyImportRow(
            id: id,
            term: term,
            definition: definition,
            phonetic: phonetic,
            example: example,
            partOfSpeech: partOfSpeech,
            tags: tags,
            note: note,
            alternatives: alternatives,
            error: error
        )
    }

    static func invalidRow(index: Int, term: String, error: String) -> VocabularyImportRow {
        makeRow(
            id: index,
            term: term.trimmingCharacters(in: .whitespacesAndNewlines),
            definition: "",
            error: error
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
