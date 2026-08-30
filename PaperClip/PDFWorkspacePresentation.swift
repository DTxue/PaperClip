import SwiftUI

extension PDFWorkspaceView {
    var activePDFURL: URL {
        session.activePDFURL(for: document)
    }

    var workspaceSnapshot: PDFWorkspaceSnapshot {
        session.workspaceSnapshot()
    }

    @ViewBuilder
    func workspacePresentationModifiers<Content: View>(_ content: Content) -> some View {
        content
            .onAppear(perform: handleWorkspaceAppear)
            .onDisappear(perform: handleWorkspaceDisappear)
            .sheet(isPresented: $session.isPDFPageExportPresented) {
                PDFPageExportView(
                    documentURL: activePDFURL,
                    drawings: session.drawings,
                    canvasSizes: session.canvasSizes
                )
            }
            .sheet(item: $session.examPageSelectionContext) { context in
                PDFExamPageSelectionView(
                    documentURL: context.documentURL,
                    decision: context.decision
                ) { pageIndex in
                    session.examPageSelectionContext = nil
                    activateAttempt(id: context.attemptID, requestedPageIndex: pageIndex)
                }
            }
            .sheet(isPresented: $session.isExamHistoryPresented) {
                ExamAttemptHistoryView(attempts: session.examHistoryAttempts) { attempt in
                    session.isExamHistoryPresented = false
                    continueExam(id: attempt)
                } onDelete: { attempt in
                    deleteInProgressExamAttempt(id: attempt)
                }
            }
            .appAlert($session.alert)
            .pdfWorkspaceConfirmationDialogs(owner: self)
    }

    func handleWorkspaceAppear() {
        do {
            try StorageService.makePDFReadOnly(at: document.localFileURL)
        } catch {
            session.alert = AppAlert(title: "无法保护原 PDF", error: error)
        }
        refreshExamSummary()
        activateInitialOrCurrentAttemptIfNeeded()
    }

    func activateInitialOrCurrentAttemptIfNeeded() {
        guard !didActivateInitialAttempt else { return }
        didActivateInitialAttempt = true
        if let initialAttemptID {
            activateAttempt(id: initialAttemptID)
            return
        }
    }

    func handleWorkspaceDisappear() {
        session.pendingSaveAction.cancel()
        session.submitTaskSlot.cancel()
        session.resetActiveExamURL()
        persistModelContext()
    }
}
