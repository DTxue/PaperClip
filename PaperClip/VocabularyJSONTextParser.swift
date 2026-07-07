import Foundation

enum VocabularyJSONTextParser {
    static func parse(_ text: String) -> [VocabularyImportRow] {
        guard let object = try? JSONSerialization.jsonObject(with: Data(text.utf8)) else {
            return [VocabularyImportRow(id: 0, term: "", definition: "", error: "JSON 格式无效")]
        }
        let dictionaries: [[String: Any]]
        if let array = object as? [[String: Any]] {
            dictionaries = array
        } else if let dictionary = object as? [String: Any] {
            dictionaries = [dictionary]
        } else {
            return [VocabularyImportRow(id: 0, term: "", definition: "", error: "JSON 顶层必须是对象或对象数组")]
        }

        return dictionaries.enumerated().map { index, item in
            let value: (String) -> String = { key in
                item[key] as? String ?? ""
            }
            let term = value("term").isEmpty ? value("word") : value("term")
            let definition = value("definition").isEmpty ? value("meaning") : value("definition")
            return VocabularyTextRowBuilder.makeRow(
                id: index,
                term: term.trimmingCharacters(in: .whitespacesAndNewlines),
                definition: definition.trimmingCharacters(in: .whitespacesAndNewlines),
                phonetic: value("phonetic"),
                example: value("example"),
                partOfSpeech: value("partOfSpeech"),
                tags: value("tags"),
                note: value("note"),
                alternatives: value("alternatives"),
                error: term.isEmpty || definition.isEmpty ? "缺少 term/word 或 definition/meaning" : nil
            )
        }
    }
}
