import Foundation

extension MistakeCardRowData {
    var imageURL: URL {
        StoredFile.cardImage(fileName: imageFileName).url
    }

    var resolvedQuestionType: QuestionType {
        QuestionType(rawValue: resolvedQuestionTypeRaw) ?? .other
    }

    var tagPreviewText: String {
        MistakeTagDisplay.preview(tags, limit: 2)
    }

    var metadataText: String {
        [
            grade,
            semester,
            resolvedQuestionType.rawValue,
            tags.first ?? ""
        ]
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
    }

    func matchesSearch(_ normalizedSearch: String) -> Bool {
        MistakeCardFilterQuery(
            searchText: normalizedSearch,
            selectedStatus: "",
            selectedQuestionType: "",
            selectedTag: "",
            selectedSource: ""
        ).matches(self)
    }

    func matchesFilters(
        selectedStatus: String,
        selectedQuestionType: String,
        selectedTag: String,
        selectedSource: String
    ) -> Bool {
        MistakeCardFilterQuery(
            searchText: "",
            selectedStatus: selectedStatus,
            selectedQuestionType: selectedQuestionType,
            selectedTag: selectedTag,
            selectedSource: selectedSource
        ).matches(self)
    }
}
