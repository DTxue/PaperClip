import UIKit
@preconcurrency import PDFKit

enum PDFRenderSupport {
    static func document(at url: URL) throws -> PDFDocument {
        try PDFDocumentReader.requireDocument(at: url)
    }

    static func opaqueImage(
        size: CGSize,
        scale: CGFloat = 1,
        actions: (UIGraphicsImageRendererContext) -> Void
    ) -> UIImage {
        ImageRenderSupport.opaqueImage(size: size, scale: scale, actions: actions)
    }

    static func jpegData(
        from image: UIImage,
        profile: ImageJPEGProfile
    ) throws -> Data {
        guard let data = ImageJPEGEncoder.adaptiveData(from: image, profile: profile) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return data
    }
}
