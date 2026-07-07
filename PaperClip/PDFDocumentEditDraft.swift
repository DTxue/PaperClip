import Foundation

struct PDFDocumentEditDraft: Equatable {
    let title: String
    let grade: String
    let semester: String
    let subject: String

    init(
        title: String,
        grade: String,
        semester: String,
        subject: String
    ) {
        self.title = title
        self.grade = grade
        self.semester = semester
        self.subject = subject
    }

    var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func resolvedTitle(fallback: String) -> String {
        let normalizedTitle = normalizedTitle
        return normalizedTitle.isEmpty ? fallback : normalizedTitle
    }

    func hasChanges(comparedTo document: PDFDocumentItem) -> Bool {
        resolvedTitle(fallback: document.title) != document.title
            || grade != document.grade
            || semester != document.semester
            || subject != document.subject
    }

    func isRenameCandidate(comparedTo currentTitle: String) -> Bool {
        let normalizedTitle = normalizedTitle
        return !normalizedTitle.isEmpty && normalizedTitle != currentTitle
    }
}
