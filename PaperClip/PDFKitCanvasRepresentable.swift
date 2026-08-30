import SwiftUI
import PDFKit
import PencilKit
import UIKit

extension PDFKitCanvasView {
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PDFDrawingHostView {
        let host = PDFDrawingHostView()
        let pdfView = host.pdfView

        if let document = try? PDFRenderSupport.document(at: url) {
            pdfView.document = document
        } else {
            MainActorScheduler.async {
                onError("文件不存在、已损坏，或不是有效的 PDF。")
            }
        }
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.displaysPageBreaks = true
        pdfView.backgroundColor = .secondarySystemBackground

        context.coordinator.attach(host: host)
        host.onLayout = { [weak coordinator = context.coordinator] in
            coordinator?.scheduleCanvasLayout()
        }
        return host
    }

    static func dismantleUIView(
        _ host: PDFDrawingHostView,
        coordinator: Coordinator
    ) {
        coordinator.tearDown()
        host.onLayout = nil
    }

    func updateUIView(_ host: PDFDrawingHostView, context: Context) {
        context.coordinator.updateFromSwiftUI(self)
    }
}
