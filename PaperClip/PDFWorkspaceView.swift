import SwiftUI
import SwiftData
import PencilKit
@preconcurrency import PDFKit

struct PDFWorkspaceView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    let document: PDFDocumentItem
    let initialAttemptID: UUID?

    @State var session = PDFWorkspaceSession()
    @State var didActivateInitialAttempt = false

    init(document: PDFDocumentItem, initialAttemptID: UUID? = nil) {
        self.document = document
        self.initialAttemptID = initialAttemptID
    }

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
                    Button("完成") { finishWorkspace() }
                        .disabled(session.isSubmittingExam)
                }

                if let activeAttempt = session.activeAttempt,
                   ExamAttemptStatus(rawValue: activeAttempt.status)?.canSubmit == true {
                    ToolbarItem(placement: .topBarTrailing) {
                        PDFExamTimerBadge(startedAt: activeAttempt.createdAt)
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    workspaceToolbarButtons
                }
            }
            .interactiveDismissDisabled(session.activeAttempt != nil || session.isSubmittingExam)
        )
    }

}
