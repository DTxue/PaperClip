import PDFKit
import PencilKit
import UIKit

extension PDFKitCanvasView.Coordinator {
    func installVisibleCanvases() {
        guard let pdfView,
              let document = pdfView.document,
              let documentView = pdfView.documentView
        else { return }

        documentView.isUserInteractionEnabled = true
        var pages = pdfView.visiblePages
        if pages.isEmpty, let currentPage = pdfView.currentPage {
            pages = [currentPage]
        }

        let pagesToRemove = VisibleElementDiff.elementsToRemove(
            existing: canvases.keys,
            visible: pages
        )
        for page in pagesToRemove {
            removeCanvas(for: page)
        }

        for page in pages where canvases[page] == nil {
            let canvas = PDFCanvasFactory.make(delegate: self)
            let pageIndex = document.index(for: page)

            pageIndexByCanvas[ObjectIdentifier(canvas)] = pageIndex
            if let data = parent.drawings[pageIndex],
               let drawing = DrawingDataSupport.drawing(from: data) {
                PDFCanvasFactory.setDrawingSilently(drawing, in: canvas, delegate: self)
            }

            canvases[page] = canvas
            documentView.addSubview(canvas)
            registerWithToolPicker(canvas)
            configure(canvas)
        }
    }

    func layoutCanvases() {
        guard let pdfView,
              let documentView = pdfView.documentView
        else { return }

        var reportedSizes: [Int: CGSize] = [:]
        for (page, canvas) in canvases {
            guard let frame = PDFPageViewGeometry.pageFrame(
                for: page,
                in: pdfView,
                documentView: documentView
            ) else { continue }

            if canvas.frame != frame {
                canvas.frame = frame
            }
            if canvas.contentSize != frame.size {
                canvas.contentSize = frame.size
            }
            UIViewLayeringSupport.bringSubviewToFrontIfNeeded(canvas, in: documentView)

            // 记录精确 canvas 尺寸（frame.size = mediaBox × scaleFactor）
            if let idx = pageIndexByCanvas[ObjectIdentifier(canvas)],
               let reportableSize = CanvasSizeReportSupport.reportableSize(frame.size) {
                reportedSizes[idx] = reportableSize
            }
        }

        reportCanvasSizesIfNeeded(reportedSizes)
        layoutGradeStamps()
    }

    func layoutGradeStamps() {
        guard let pdfView else { return }
        gradeStampLayout.layout(parent.gradeStamps, in: pdfView)
    }
}
