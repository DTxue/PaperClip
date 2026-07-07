import SwiftData
import SwiftUI

struct PDFDocumentLoader<Content: View>: View {
    @Environment(\.modelContext) private var modelContext
    let documentID: UUID
    let content: (PDFDocumentItem) -> Content

    @State private var document: PDFDocumentItem?
    @State private var didLoad = false
    @State private var alert: AppAlert?

    var body: some View {
        Group {
            if let document {
                content(document)
            } else if didLoad {
                ContentUnavailableView("试卷不存在", systemImage: "doc")
            } else {
                ProgressView("正在载入试卷…")
            }
        }
        .task(id: documentID) {
            loadDocument()
        }
        .appAlert($alert)
    }

    private func loadDocument() {
        do {
            didLoad = false
            document = try modelContext.fetchPDFDocument(id: documentID)
            didLoad = true
        } catch {
            document = nil
            didLoad = true
            alert = AppAlert(title: "无法读取试卷", error: error)
        }
    }
}
