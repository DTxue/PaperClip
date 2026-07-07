import CoreGraphics
import Foundation

struct ImageJPEGProfile: Equatable {
    let maximumBytes: Int
    let qualities: [CGFloat]

    static let examPage = ImageJPEGProfile(
        maximumBytes: 6 * 1024 * 1024,
        qualities: [0.86, 0.76, 0.66, 0.56]
    )

    static let longPDFImage = ImageJPEGProfile(
        maximumBytes: 12 * 1024 * 1024,
        qualities: [0.9, 0.82, 0.74, 0.66]
    )

    static let reviewSubmission = longPDFImage

    static let aiRequest = ImageJPEGProfile(
        maximumBytes: 8 * 1024 * 1024,
        qualities: [0.82, 0.74, 0.66, 0.58]
    )

    static let aiRequestFallback = ImageJPEGProfile(
        maximumBytes: aiRequest.maximumBytes,
        qualities: [0.5]
    )
}
