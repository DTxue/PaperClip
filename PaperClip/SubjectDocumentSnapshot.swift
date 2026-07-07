import Foundation

struct SubjectDocumentSnapshot {
    let documents: [PDFDocumentRowData]
    let filteredDocuments: [PDFDocumentRowData]

    init(
        documents: [PDFDocumentRowData],
        searchText: String,
        selectedGrade: String,
        selectedSemester: String
    ) {
        var filteredDocuments: [PDFDocumentRowData] = []
        filteredDocuments.reserveCapacity(documents.count)

        for document in documents {
            if document.matchesSearch(searchText)
                && document.matchesFilters(
                    selectedGrade: selectedGrade,
                    selectedSemester: selectedSemester
                ) {
                filteredDocuments.append(document)
            }
        }

        self.documents = documents
        self.filteredDocuments = filteredDocuments
    }
}
