import Foundation
import SwiftData

struct PDFImportRequest {
    let grade: String
    let semester: String
    let subject: String

    static func libraryDefault(
        defaultGrade: String,
        defaultSemester: String,
        preferredSubjectsRaw: String
    ) -> PDFImportRequest {
        PDFImportRequest(
            grade: defaultGrade,
            semester: defaultSemester,
            subject: PreferredSubjects.defaultSubject(preferredSubjectsRaw)
        )
    }

    static func subjectDefault(
        subject: String,
        selectedGrade: String,
        selectedSemester: String,
        defaultGrade: String,
        defaultSemester: String
    ) -> PDFImportRequest {
        PDFImportRequest(
            grade: selectedGrade.isEmpty ? defaultGrade : selectedGrade,
            semester: selectedSemester.isEmpty ? defaultSemester : selectedSemester,
            subject: subject
        )
    }
}

@MainActor
enum PDFImporter {
    static func importPDF(
        from result: Result<[URL], Error>,
        request: PDFImportRequest,
        modelContext: ModelContext
    ) throws -> PDFDocumentItem {
        guard let url = try result.get().first else { throw CocoaError(.fileNoSuchFile) }
        let imported = try StorageService.importPDF(from: url)
        let item = PDFDocumentItem(
            title: imported.title,
            localFileName: imported.fileName,
            fileFingerprint: try StorageService.sha256Fingerprint(
                for: StoredFile.importedPDF(fileName: imported.fileName).url
            ),
            grade: request.grade,
            semester: request.semester,
            subject: request.subject
        )
        modelContext.insert(item)
        do {
            try modelContext.saveOrRollbackIfNeeded()
        } catch {
            StorageService.deleteFileBestEffort(
                .importedPDF(fileName: imported.fileName),
                context: "导入失败后的 PDF 清理失败"
            )
            throw error
        }
        return item
    }
}
