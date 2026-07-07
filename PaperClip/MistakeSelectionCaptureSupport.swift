import Foundation

struct MistakeSelectionCaptureRequest: Equatable {
    let imageFileName: String
    let originalWidth: Double
    let originalHeight: Double
    let sourceDocumentTitle: String

    init?(
        imageFileName: String,
        originalWidth: Double,
        originalHeight: Double,
        sourceDocumentTitle: String
    ) {
        guard !imageFileName.isEmpty,
              Self.isValidOriginalDimension(originalWidth),
              Self.isValidOriginalDimension(originalHeight)
        else { return nil }

        self.imageFileName = imageFileName
        self.originalWidth = originalWidth
        self.originalHeight = originalHeight
        self.sourceDocumentTitle = sourceDocumentTitle
    }

    static func isValidOriginalDimension(_ value: Double) -> Bool {
        value.isFinite && value > 0
    }
}

enum MistakeSelectionCaptureSupport {
    static func makeRequest(
        imageFileName: String,
        originalWidth: Double,
        originalHeight: Double,
        sourceDocumentTitle: String
    ) -> MistakeSelectionCaptureRequest? {
        MistakeSelectionCaptureRequest(
            imageFileName: imageFileName,
            originalWidth: originalWidth,
            originalHeight: originalHeight,
            sourceDocumentTitle: sourceDocumentTitle
        )
    }
}
