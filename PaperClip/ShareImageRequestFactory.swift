import UIKit

enum ShareImageRequestFactory {
    static func request(from data: Data) -> ShareImageRequest {
        ShareImageRequest(data: data)
    }

    static func request(
        from image: UIImage,
        priority: TaskPriority = .userInitiated
    ) async throws -> ShareImageRequest {
        guard let data = await ImageJPEGEncoder.standardData(from: image, priority: priority) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return ShareImageRequest(data: data)
    }
}
