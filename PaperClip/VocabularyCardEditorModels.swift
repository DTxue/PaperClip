import Foundation

struct VocabularyCardEditDraft: Equatable {
    var term: String
    var definition: String
    var phonetic: String
    var example: String
    var partOfSpeech: String
    var tagsText: String
    var note: String
    var alternativeAnswersText: String

    init(card: VocabularyCard? = nil) {
        self.term = card?.term ?? ""
        self.definition = card?.definition ?? ""
        self.phonetic = card?.phonetic ?? ""
        self.example = card?.example ?? ""
        self.partOfSpeech = card?.partOfSpeech ?? ""
        self.tagsText = card?.tagsText ?? ""
        self.note = card?.note ?? ""
        self.alternativeAnswersText = card?.alternativeAnswersText ?? ""
    }

    var canSave: Bool {
        !term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !definition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var snapshot: VocabularyCardEditSnapshot {
        VocabularyCardEditSnapshot(
            term: term,
            definition: definition,
            phonetic: phonetic,
            example: example,
            partOfSpeech: partOfSpeech,
            tagsText: tagsText,
            note: note,
            alternativeAnswersText: alternativeAnswersText
        )
    }
}

struct VocabularyCardEditSnapshot: Equatable {
    let term: String
    let definition: String
    let phonetic: String
    let example: String
    let partOfSpeech: String
    let tagsText: String
    let note: String
    let alternativeAnswersText: String

    init(
        term: String,
        definition: String,
        phonetic: String,
        example: String,
        partOfSpeech: String,
        tagsText: String,
        note: String,
        alternativeAnswersText: String
    ) {
        self.term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        self.definition = definition.trimmingCharacters(in: .whitespacesAndNewlines)
        self.phonetic = phonetic
        self.example = example
        self.partOfSpeech = partOfSpeech
        self.tagsText = tagsText
        self.note = note
        self.alternativeAnswersText = alternativeAnswersText
    }

    init(card: VocabularyCard) {
        self.init(
            term: card.term,
            definition: card.definition,
            phonetic: card.phonetic,
            example: card.example,
            partOfSpeech: card.partOfSpeech,
            tagsText: card.tagsText,
            note: card.note,
            alternativeAnswersText: card.alternativeAnswersText
        )
    }

    func apply(to card: VocabularyCard) {
        card.term = term
        card.definition = definition
        card.phonetic = phonetic
        card.example = example
        card.partOfSpeech = partOfSpeech
        card.tagsText = tagsText
        card.note = note
        card.alternativeAnswersText = alternativeAnswersText
    }
}
