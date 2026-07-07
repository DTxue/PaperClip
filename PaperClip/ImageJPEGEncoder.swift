import UIKit

enum ImageJPEGEncoder {
    static let standardQuality: CGFloat = 0.92

    static func standardData(from image: UIImage) -> Data? {
        image.jpegData(compressionQuality: standardQuality)
    }

    static func standardData(
        from image: UIImage,
        priority: TaskPriority = .userInitiated
    ) async -> Data? {
        await Task.detached(priority: priority) {
            standardData(from: image)
        }.value
    }

    static func adaptiveData(
        from image: UIImage,
        maximumBytes: Int,
        qualities: [CGFloat]
    ) -> Data? {
        var fallbackData: Data?
        for quality in qualities {
            guard let data = image.jpegData(compressionQuality: quality) else { continue }
            if data.count <= maximumBytes {
                return data
            }
            fallbackData = data
        }
        return fallbackData ?? image.jpegData(compressionQuality: qualities.last ?? standardQuality)
    }

    static func adaptiveData(
        from image: UIImage,
        profile: ImageJPEGProfile
    ) -> Data? {
        adaptiveData(
            from: image,
            maximumBytes: profile.maximumBytes,
            qualities: profile.qualities
        )
    }

    static func adaptiveData(
        from image: UIImage,
        profile: ImageJPEGProfile,
        priority: TaskPriority = .userInitiated
    ) async -> Data? {
        await Task.detached(priority: priority) {
            adaptiveData(from: image, profile: profile)
        }.value
    }
}
