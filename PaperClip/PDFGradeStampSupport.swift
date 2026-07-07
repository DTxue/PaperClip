import UIKit
import PDFKit

@MainActor
final class PDFGradeStampLayoutCoordinator {
    private static let normalizedHorizontalOffset: CGFloat = 0.045
    private var stampViews: [UUID: UILabel] = [:]
    private var stampIndex = PDFGradeStampIndex()

    func layout(_ stamps: [PDFGradeStamp], in pdfView: PDFView) {
        guard let document = pdfView.document,
              let documentView = pdfView.documentView
        else { return }

        stampIndex.updateIfNeeded(stamps)
        let visibleStamps = visibleStamps(in: pdfView, document: document)
        removeHiddenStampViews(visibleStamps)
        var pageFrameByIndex: [Int: CGRect] = [:]
        pageFrameByIndex.reserveCapacity(visibleStamps.count)

        for stamp in visibleStamps {
            let frame: CGRect
            if let cachedFrame = pageFrameByIndex[stamp.pageIndex] {
                frame = cachedFrame
            } else {
                guard let page = document.page(at: stamp.pageIndex),
                      let resolvedFrame = PDFPageViewGeometry.pageFrame(
                        for: page,
                        in: pdfView,
                        documentView: documentView
                      )
                else { continue }
                pageFrameByIndex[stamp.pageIndex] = resolvedFrame
                frame = resolvedFrame
            }

            let view = stampViews[stamp.id] ?? PDFGradeStampLabelFactory.makeLabel(for: stamp)
            stampViews[stamp.id] = view
            if view.superview == nil {
                documentView.addSubview(view)
            }
            UIViewLayeringSupport.bringSubviewToFrontIfNeeded(view, in: documentView)
            PDFGradeStampLabelFactory.configure(view, for: stamp)

            let center = CGPoint(
                x: frame.minX + min(stamp.normalizedAnchor.x + Self.normalizedHorizontalOffset, 0.96) * frame.width,
                y: frame.minY + stamp.normalizedAnchor.y * frame.height
            )
            view.bounds = CGRect(x: 0, y: 0, width: 34, height: 34)
            view.center = center
            view.layer.zPosition = 20
        }
    }

    func removeAll() {
        for view in stampViews.values {
            view.removeFromSuperview()
        }
        stampViews.removeAll()
        stampIndex.removeAll()
    }

    private func visibleStamps(in pdfView: PDFView, document: PDFDocument) -> [PDFGradeStamp] {
        var visiblePageIndices: Set<Int> = []
        for page in pdfView.visiblePages {
            let index = document.index(for: page)
            if index >= 0 {
                visiblePageIndices.insert(index)
            }
        }
        if visiblePageIndices.isEmpty,
           let currentPage = pdfView.currentPage {
            let index = document.index(for: currentPage)
            if index >= 0 {
                visiblePageIndices.insert(index)
            }
        }

        return stampIndex.stamps(on: visiblePageIndices)
    }

    private func removeHiddenStampViews(_ visibleStamps: [PDFGradeStamp]) {
        var visibleStampIDs: Set<UUID> = []
        visibleStampIDs.reserveCapacity(visibleStamps.count)
        for stamp in visibleStamps {
            visibleStampIDs.insert(stamp.id)
        }
        let hiddenStampIDs = stampViews.keys.filter { !visibleStampIDs.contains($0) }
        for id in hiddenStampIDs {
            stampViews.removeValue(forKey: id)?.removeFromSuperview()
        }
    }

}
