import Foundation

extension PDFKitCanvasView.Coordinator {
    func updateFromSwiftUI(_ parent: PDFKitCanvasView) {
        self.parent = parent
        updateDocumentIfNeeded(url: parent.url)
        configurePDFInteractionIfNeeded()
        updateCanvasesIfNeeded()
        applyPageNavigationIfNeeded()
        let changes = consumeSwiftUIUpdate()
        if changes.needsLayout {
            scheduleCanvasLayoutForSwiftUIUpdateIfNeeded()
        }
        updateToolPickerVisibility()
        applySwiftUIChanges(changes)
    }

    func consumeSwiftUIUpdate() -> PDFCanvasUpdateChanges {
        updateState.consume(
            PDFCanvasUpdateSnapshot(
                layoutInputs: PDFCanvasLayoutInputs(
                    url: parent.url,
                    gradeStamps: parent.gradeStamps
                ),
                commandTokens: PDFCanvasCommandTokens(
                    undo: parent.undoToken,
                    redo: parent.redoToken,
                    clearAnswers: parent.clearAnswersToken,
                    reloadDrawings: parent.reloadDrawingsToken
                )
            )
        )
    }

    func scheduleCanvasLayout() {
        guard !isCanvasLayoutScheduled else { return }
        isCanvasLayoutScheduled = true

        MainActorScheduler.async { [weak self] in
            guard let self else { return }
            isCanvasLayoutScheduled = false
            configurePDFInteractionIfNeeded()
            installVisibleCanvases()
            layoutCanvases()
            updateToolPickerVisibility()
        }
    }

    func scheduleCanvasLayoutForSwiftUIUpdateIfNeeded() {
        scheduleCanvasLayout()
    }

    private func applySwiftUIChanges(_ changes: PDFCanvasUpdateChanges) {
        if changes.undoChanged {
            activeCanvas?.undoManager?.undo()
        }
        if changes.redoChanged {
            activeCanvas?.undoManager?.redo()
        }
        if changes.clearAnswersChanged {
            clearAllDrawings()
        }
        if changes.reloadDrawingsChanged {
            reloadAllCanvases()
        }
    }
}
