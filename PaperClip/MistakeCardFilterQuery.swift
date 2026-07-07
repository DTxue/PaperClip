import Foundation

struct MistakeCardFilterQuery {
    let normalizedSearch: String
    let selectedStatus: String
    let selectedQuestionType: String
    let selectedTag: String
    let selectedSource: String

    init(
        searchText: String,
        selectedStatus: String,
        selectedQuestionType: String,
        selectedTag: String,
        selectedSource: String
    ) {
        normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.selectedStatus = selectedStatus
        self.selectedQuestionType = selectedQuestionType
        self.selectedTag = selectedTag
        self.selectedSource = selectedSource
    }

    func matches(_ card: MistakeCardRowData) -> Bool {
        let resolvedQuestionType = card.resolvedQuestionTypeRaw
        return matchesSearch(card, resolvedQuestionType: resolvedQuestionType)
            && matchesFilters(card, resolvedQuestionType: resolvedQuestionType)
    }

    private func matchesSearch(
        _ card: MistakeCardRowData,
        resolvedQuestionType: String
    ) -> Bool {
        normalizedSearch.isEmpty
            || card.subject.localizedCaseInsensitiveContains(normalizedSearch)
            || card.grade.localizedCaseInsensitiveContains(normalizedSearch)
            || card.tagsText.localizedCaseInsensitiveContains(normalizedSearch)
            || card.note.localizedCaseInsensitiveContains(normalizedSearch)
            || card.recognizedText.localizedCaseInsensitiveContains(normalizedSearch)
            || card.correctAnswer.localizedCaseInsensitiveContains(normalizedSearch)
            || resolvedQuestionType.localizedCaseInsensitiveContains(normalizedSearch)
            || card.sourceDocumentTitle.localizedCaseInsensitiveContains(normalizedSearch)
    }

    private func matchesFilters(
        _ card: MistakeCardRowData,
        resolvedQuestionType: String
    ) -> Bool {
        (selectedStatus.isEmpty || card.status == selectedStatus)
            && (selectedQuestionType.isEmpty || resolvedQuestionType == selectedQuestionType)
            && (selectedTag.isEmpty || card.tags.contains(selectedTag))
            && (selectedSource.isEmpty || card.sourceDocumentTitle == selectedSource)
    }
}
