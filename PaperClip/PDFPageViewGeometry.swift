import PDFKit
import UIKit

@MainActor
enum PDFPageViewGeometry {
    static func pageFrame(
        for page: PDFPage,
        in pdfView: PDFView,
        documentView: UIView? = nil
    ) -> CGRect? {
        guard let documentView = documentView ?? pdfView.documentView else { return nil }
        let pageRect = pdfView.convert(page.bounds(for: .mediaBox), from: page)
        let frame = documentView.convert(pageRect, from: pdfView).standardized
        guard frame.width > 1, frame.height > 1 else { return nil }
        return frame
    }
}
