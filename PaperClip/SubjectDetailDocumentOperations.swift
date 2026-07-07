import SwiftData
import SwiftUI

extension SubjectDetailView {
    func importPDF(from result: Result<[URL], Error>) {
        do {
            let document = try PDFImporter.importPDF(
                from: result,
                request: .subjectDefault(
                    subject: subject,
                    selectedGrade: selectedGrade,
                    selectedSemester: selectedSemester,
                    defaultGrade: defaultGrade,
                    defaultSemester: defaultSemester
                ),
                modelContext: modelContext
            )
            selectedDocument = PDFDocumentRowData(document: document)
            refreshDocuments()
        } catch {
            alert = AppAlert(title: "无法导入 PDF", error: error)
        }
    }

    func refreshDocuments() {
        do {
            documents = try modelContext.fetchPDFDocumentRows(subject: subject)
        } catch {
            documents = []
            alert = AppAlert(title: "无法读取试卷", error: error)
        }
    }

    func openDocument(_ row: PDFDocumentRowData) {
        do {
            guard let openedDocument = try modelContext.openPDFDocumentRow(row) else {
                alert = AppAlert(title: "无法打开试卷", message: "该试卷不存在或已被删除。")
                refreshDocuments()
                return
            }
            selectedDocument = openedDocument
            refreshDocuments()
        } catch {
            alert = AppAlert(title: "无法打开试卷", error: error)
        }
    }

    func deleteDocument(_ document: PDFDocumentRowData) {
        var fileURLsToDelete: [URL] = []
        do {
            fileURLsToDelete = try modelContext.deletePDFDocumentCascade(row: document)
            refreshDocuments()
        } catch {
            alert = AppAlert(title: "无法删除试卷", error: error)
            return
        }

        do {
            try StorageService.deleteFiles(at: fileURLsToDelete)
        } catch {
            alert = AppAlert(title: "试卷记录已删除，文件清理失败", error: error)
        }
    }
}
