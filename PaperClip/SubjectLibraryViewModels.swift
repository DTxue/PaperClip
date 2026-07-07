import Foundation
import SwiftData

enum SubjectTopSection: String, Hashable {
    case papers = "试卷"
    case mistakes = "错题"
}

struct PDFDocumentRowData: Identifiable, Hashable {
    static var propertiesToFetch: [PartialKeyPath<PDFDocumentItem>] {
        [
            \.id,
            \.title,
            \.localFileName,
            \.fileFingerprint,
            \.lastOpenDate,
            \.grade,
            \.semester,
            \.subject
        ]
    }

    let id: UUID
    let title: String
    let localFileName: String
    let fileFingerprint: String
    let lastOpenDate: Date
    let grade: String
    let semester: String
    let subject: String

    init(document: PDFDocumentItem) {
        id = document.id
        title = document.title
        localFileName = document.localFileName
        fileFingerprint = document.fileFingerprint
        lastOpenDate = document.lastOpenDate
        grade = document.grade
        semester = document.semester
        subject = document.subject
    }

    var localFileURL: URL {
        StoredFile.importedPDF(fileName: localFileName).url
    }

    var metadataText: String {
        [grade, semester, subject]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    func matchesSearch(_ searchText: String) -> Bool {
        searchText.isEmpty || title.localizedCaseInsensitiveContains(searchText)
    }

    func matchesFilters(selectedGrade: String, selectedSemester: String) -> Bool {
        let matchesGrade = selectedGrade.isEmpty || grade == selectedGrade
        let matchesSemester = selectedSemester.isEmpty || semester == selectedSemester
        return matchesGrade && matchesSemester
    }
}

extension ModelContext {
    func fetchPDFDocumentRows(subject: String) throws -> [PDFDocumentRowData] {
        try fetchPDFDocuments(
            subject: subject,
            propertiesToFetch: PDFDocumentRowData.propertiesToFetch
        ).map(PDFDocumentRowData.init)
    }

    func openPDFDocumentRow(_ row: PDFDocumentRowData) throws -> PDFDocumentRowData? {
        guard let document = try fetchPDFDocument(id: row.id) else { return nil }
        document.lastOpenDate = .now
        try saveOrRollbackIfNeeded()
        return PDFDocumentRowData(document: document)
    }

    func deletePDFDocumentCascade(row: PDFDocumentRowData) throws -> [URL] {
        let fileURLsToDelete = try deletePDFDocumentCascade(
            documentID: row.id,
            localFileURL: row.localFileURL
        )
        try saveOrRollbackIfNeeded()
        return fileURLsToDelete
    }
}
