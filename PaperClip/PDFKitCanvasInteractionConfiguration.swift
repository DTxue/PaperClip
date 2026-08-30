extension PDFKitCanvasView.Coordinator {
    func configurePDFInteraction() {
        guard let pdfView else { return }

        pdfInteraction.configure(
            pdfView: pdfView,
            configureGestureTouchTypes: needsPDFGestureTouchConfiguration
        )
        needsPDFGestureTouchConfiguration = false
        needsPDFInteractionConfiguration = false
    }

    func configurePDFInteractionIfNeeded() {
        guard needsPDFInteractionConfiguration else { return }
        configurePDFInteraction()
    }
}
