import SwiftUI
import SwiftData
import PencilKit
@preconcurrency import PDFKit

struct PDFWorkspaceView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    let document: PDFDocumentItem

    @State var session = PDFWorkspaceSession()

    var body: some View {
        workspacePresentationModifiers(
            NavigationStack {
                workspaceCanvas
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("完成") { dismiss() }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    workspaceToolbarButtons
                }
            }
        )
    }

}
