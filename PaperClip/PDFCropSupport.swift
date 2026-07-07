import UIKit
import PDFKit

enum PDFCropRenderer {
    static func image(
        pdfURL: URL,
        pageIndex: Int,
        cropRect: CGRect
    ) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            guard let document = try? PDFRenderSupport.document(at: pdfURL),
                  let page = document.page(at: pageIndex)
            else { return nil }
            guard !Task.isCancelled else { return nil }
            return image(from: page, cropRect: cropRect)
        }.value
    }

    static func image(from page: PDFPage, cropRect: CGRect) -> UIImage? {
        let pageBounds = page.bounds(for: .mediaBox)
        guard let boundedCrop = PDFCropGeometry.boundedCrop(cropRect, in: pageBounds),
              let outputSize = PDFCropGeometry.outputSize(for: boundedCrop)
        else { return nil }

        return PDFRenderSupport.opaqueImage(size: outputSize) { context in
            let destination = CGRect(origin: .zero, size: outputSize)
            PDFDrawingRenderSupport.fillWhiteBackground(in: destination, context: context)
            PDFDrawingRenderSupport.drawPDFPage(
                page,
                bounds: boundedCrop,
                in: destination,
                context: context.cgContext,
                clip: true
            )
        }
    }
}

@MainActor
final class PDFCropTaskCoordinator {
    private var task: Task<Void, Never>?
    private var taskID = UUID()

    func start(
        pdfURL: URL,
        pageIndex: Int,
        cropRect: CGRect,
        action: PDFSelectionAction,
        onCrop: @escaping (UIImage, Double, Double, PDFSelectionAction) -> Void
    ) {
        cancel()
        let currentID = UUID()
        taskID = currentID
        task = Task { @MainActor in
            defer {
                if taskID == currentID {
                    task = nil
                }
            }
            guard let image = await PDFCropRenderer.image(
                pdfURL: pdfURL,
                pageIndex: pageIndex,
                cropRect: cropRect
            ) else { return }
            guard taskID == currentID, !Task.isCancelled else { return }
            onCrop(
                image,
                cropRect.width,
                cropRect.height,
                action
            )
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        taskID = UUID()
    }
}
