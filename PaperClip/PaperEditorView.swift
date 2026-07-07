import SwiftData
import SwiftUI

struct PaperEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let document: PDFDocumentItem
    @State private var alert: AppAlert?
    @State private var title: String
    @State private var grade: String
    @State private var semester: String
    @State private var subject: String

    init(document: PDFDocumentItem) {
        self.document = document
        _title = State(initialValue: document.title)
        _grade = State(initialValue: document.grade)
        _semester = State(initialValue: document.semester)
        _subject = State(initialValue: document.subject)
    }

    var body: some View {
        Form {
            Section("名称") {
                TextField("试卷名称", text: $title)
            }
            Section("分类") {
                Picker("年级", selection: $grade) {
                    ForEach(Grade.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                Picker("学期", selection: $semester) {
                    ForEach(Semester.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                Picker("学科", selection: $subject) {
                    ForEach(Subject.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
            }
        }
        .navigationTitle("编辑试卷")
        .navigationBarTitleDisplayMode(.inline)
        .editSheetToolbar(
            confirmTitle: "完成",
            onCancel: { dismiss() },
            onConfirm: save
        )
        .appAlert($alert)
    }

    private func save() {
        let editDraft = PDFDocumentEditDraft(
            title: title,
            grade: grade,
            semester: semester,
            subject: subject
        )
        guard editDraft.hasChanges(comparedTo: document) else {
            dismiss()
            return
        }

        document.title = editDraft.resolvedTitle(fallback: document.title)
        document.grade = editDraft.grade
        document.semester = editDraft.semester
        document.subject = editDraft.subject
        do {
            try modelContext.saveOrRollbackIfNeeded()
            dismiss()
        } catch {
            alert = AppAlert(title: "无法保存试卷", error: error)
        }
    }
}
