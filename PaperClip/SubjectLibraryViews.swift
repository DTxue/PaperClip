import SwiftUI
import SwiftData

// MARK: - 题库（按学科入口）

struct SubjectLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("preferredSubjects") private var preferredSubjectsRaw = ""
    @AppStorage("defaultGrade") private var defaultGrade = Grade.grade7.rawValue
    @AppStorage("defaultSemester") private var defaultSemester = Semester.first.rawValue

    @State private var isImporterPresented = false
    @State private var selectedDocument: PDFDocumentItem?
    @State private var snapshot = SubjectLibrarySnapshot.empty
    @State private var alert: AppAlert?

    var body: some View {
        SubjectLibraryContentView(snapshot: snapshot) {
            isImporterPresented = true
        }
        .navigationTitle("题库")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isImporterPresented = true } label: {
                    Label("新增 PDF", systemImage: "plus")
                }
            }
        }
        .paperClipPDFFileImporter(isPresented: $isImporterPresented) { result in
            importPDF(from: result)
        }
        .fullScreenCover(item: $selectedDocument) { document in
            PDFWorkspaceView(document: document)
        }
        .onAppear {
            refreshSnapshot()
        }
        .onChange(of: preferredSubjectsRaw) {
            refreshSnapshot()
        }
        .appAlert($alert)
    }

    private func refreshSnapshot() {
        do {
            snapshot = try SubjectLibrarySnapshot.load(
                preferredSubjectsRaw: preferredSubjectsRaw,
                modelContext: modelContext
            )
        } catch {
            alert = AppAlert(title: "无法读取题库概况", error: error)
        }
    }

    private func importPDF(from result: Result<[URL], Error>) {
        do {
            selectedDocument = try PDFImporter.importPDF(
                from: result,
                request: .libraryDefault(
                    defaultGrade: defaultGrade,
                    defaultSemester: defaultSemester,
                    preferredSubjectsRaw: preferredSubjectsRaw
                ),
                modelContext: modelContext
            )
            refreshSnapshot()
        } catch {
            alert = AppAlert(title: "无法导入 PDF", error: error)
        }
    }
}
