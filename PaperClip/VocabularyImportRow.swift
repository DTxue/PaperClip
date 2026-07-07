struct VocabularyImportRow: Identifiable, Equatable {
    let id: Int
    var term: String
    var definition: String
    var phonetic: String = ""
    var example: String = ""
    var partOfSpeech: String = ""
    var tags: String = ""
    var note: String = ""
    var alternatives: String = ""
    var error: String?

    var isValid: Bool {
        error == nil && !term.isEmpty && !definition.isEmpty
    }
}
