import Foundation
import Photos

enum PhotoLibraryImageSaveResult {
    case saved
    case denied
}

enum PhotoLibraryImageWriter {
    static func saveJPEGData(_ data: Data) async throws -> PhotoLibraryImageSaveResult {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            return .denied
        }

        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: data, options: nil)
        }
        return .saved
    }
}
