extension PDFKitCanvasView.Coordinator {
    func configurePDFInteraction() {
        guard let pdfView else { return }

        pdfInteraction.configure(
            pdfView: pdfView,
            selectionGesture: selectionGesture,
            isSelectionMode: parent.isSelectionMode,
            configureGestureTouchTypes: needsPDFGestureTouchConfiguration
        )
        needsPDFGestureTouchConfiguration = false
        needsPDFInteractionConfiguration = false
        lastConfiguredSelectionMode = parent.isSelectionMode
    }

    func configurePDFInteractionIfNeeded() {
        guard needsPDFInteractionConfiguration
            || lastConfiguredSelectionMode != parent.isSelectionMode
        else { return }
        configurePDFInteraction()
    }
}
