import SwiftData
import SwiftUI

struct SubjectDetailView: View {
    let subject: String

    @Environment(\.modelContext) var modelContext
    @AppStorage("defaultGrade") var defaultGrade = Grade.grade7.rawValue
    @AppStorage("defaultSemester") var defaultSemester = Semester.first.rawValue

    @State var topSection: SubjectTopSection = .papers
    @State var mistakeSection: SubjectMistakeSection? = .mistakes
    @State var searchText = ""
    @State var selectedGrade = ""
    @State var selectedSemester = ""
    @State var isImporterPresented = false
    @State var documents: [PDFDocumentRowData] = []
    @State var selectedDocument: PDFDocumentRowData?
    @State var editingDocument: PDFDocumentRowData?
    @State var documentToDelete: PDFDocumentRowData?
    @State var alert: AppAlert?

    private var documentSnapshot: SubjectDocumentSnapshot {
        SubjectDocumentSnapshot(
            documents: documents,
            searchText: searchText,
            selectedGrade: selectedGrade,
            selectedSemester: selectedSemester
        )
    }

    var body: some View {
        PaperClipNavigationSplitView {
            SubjectDetailSidebarView(
                topSection: $topSection,
                mistakeSection: $mistakeSection,
                selectedGrade: $selectedGrade,
                selectedSemester: $selectedSemester
            )
            .paperClipSidebarColumn(subject)
            .toolbar {
                if topSection == .papers {
                    ToolbarItem(placement: .primaryAction) {
                        Button { isImporterPresented = true } label: {
                            Label("新增 PDF", systemImage: "plus")
                        }
                    }
                }
            }
        } detail: {
            switch topSection {
            case .papers:
                SubjectPaperDocumentListView(
                    snapshot: documentSnapshot,
                    onOpen: openDocument,
                    onRefresh: refreshDocuments,
                    onEdit: { editingDocument = $0 },
                    onDelete: { documentToDelete = $0 }
                )
                .navigationTitle(subject)
                .searchable(text: $searchText, prompt: "搜索试卷")
            case .mistakes:
                SubjectMistakesView(subject: subject, section: mistakeSection)
            }
        }
        .paperClipPDFFileImporter(isPresented: $isImporterPresented) { result in
            importPDF(from: result)
        }
        .fullScreenCover(item: $selectedDocument) { document in
            PDFDocumentLoader(documentID: document.id) { document in
                PDFWorkspaceView(document: document)
            }
        }
        .sheet(item: $editingDocument) { document in
            NavigationStack {
                PDFDocumentLoader(documentID: document.id) { document in
                    PaperEditorView(document: document)
                }
            }
        }
        .onChange(of: editingDocument?.id) { oldValue, newValue in
            if oldValue != nil && newValue == nil {
                refreshDocuments()
            }
        }
        .deleteConfirmationDialog(
            item: $documentToDelete,
            title: { "删除试卷「\($0.title)」？" },
            message: { _ in "同时删除该试卷的所有答题记录，无法撤销。" },
            onDelete: deleteDocument
        )
        .appAlert($alert)
        .task(id: subject) {
            refreshDocuments()
        }
    }

}
