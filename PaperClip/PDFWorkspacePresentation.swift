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
            .sheet(item: $session.currentCard) { card in
                NavigationStack {
                    MistakeCardEditorView(card: card)
                }
            }
            .sheet(item: $session.aiAnalysisRequest) { request in
                AIAnalysisView(image: request.image)
            }
            .sheet(isPresented: $session.isPDFPageExportPresented) {
                PDFPageExportView(
                    documentURL: activePDFURL,
                    drawings: session.drawings,
                    canvasSizes: session.canvasSizes
                )
            }
            .sheet(isPresented: $session.isPageSelectionPresented) {
                PDFExamPageSelectionView(documentURL: document.localFileURL) { indices in
                    startExam(with: indices)
                }
            }
            .sheet(isPresented: $session.isExamHistoryPresented) {
                ExamAttemptHistoryView(attempts: session.examHistoryAttempts) { attempt in
                    session.isExamHistoryPresented = false
                    activateAttempt(id: attempt)
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
    }

    func handleWorkspaceDisappear() {
        session.pendingSaveAction.cancel()
        session.submitTaskSlot.cancel()
        cancelSelectionActionTask()
        session.resetActiveExamURL()
        persistModelContext()
    }
}
