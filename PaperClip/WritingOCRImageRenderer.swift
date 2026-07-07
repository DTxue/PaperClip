import CoreImage
import PencilKit
import UIKit

enum WritingOCRImageRenderer {
    static func render(
        drawing: PKDrawing,
        paperSize: CGSize,
        blackPaperMode: Bool
    ) async throws -> UIImage {
        try await Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            let image = renderSync(
                drawing: drawing,
                paperSize: paperSize,
                blackPaperMode: blackPaperMode
            )
            try Task.checkCancellation()
            return image
        }.value
    }

    private static func renderSync(
        drawing: PKDrawing,
        paperSize: CGSize,
        blackPaperMode: Bool
    ) -> UIImage {
        let spec = HandwritingRenderGeometry.fullCanvasSpec(canvasSize: paperSize)
            ?? HandwritingRenderSpec(
                sourceRect: CGRect(origin: .zero, size: paperSize),
                outputSize: paperSize,
                drawingScale: 2
            )
        let rect = spec.sourceRect
        let image = ImageRenderSupport.opaqueImage(
            size: spec.outputSize,
            scale: spec.drawingScale
        ) { context in
            ImageRenderSupport.fill(
                blackPaperMode ? .black : .white,
                in: rect,
                context: context
            )
            let drawingImage = drawing.image(from: rect, scale: spec.drawingScale)
            drawingImage.draw(in: rect)
        }
        return blackPaperMode ? (image.invertedForOCR() ?? image) : image
    }
}

private extension UIImage {
    static let ocrInversionContext = CIContext()

    func invertedForOCR() -> UIImage? {
        guard let input = CIImage(image: self),
              let filter = CIFilter(name: "CIColorInvert") else {
            return nil
        }
        filter.setValue(input, forKey: kCIInputImageKey)
        guard let output = filter.outputImage,
              let cgImage = Self.ocrInversionContext.createCGImage(output, from: output.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }
}
