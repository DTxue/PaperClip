import Foundation
import UIKit

extension AIService {
    static func imageContent(from image: UIImage) throws -> ResponsesRequest.Content {
        .image(url: try makeImageDataURL(from: image))
    }

    static func imageContent(fromJPEGData data: Data) throws -> ResponsesRequest.Content {
        .image(url: try makeImageDataURL(fromJPEGData: data))
    }

    static func makeImageDataURL(from image: UIImage) throws -> String {
        let data = try encodedJPEGData(from: image)
        return try makeImageDataURL(fromJPEGData: data)
    }

    static func makeImageDataURL(fromJPEGData data: Data) throws -> String {
        guard !data.isEmpty else {
            throw AIServiceError.invalidImage
        }
        guard data.count <= ImageJPEGProfile.aiRequest.maximumBytes else {
            throw AIServiceError.imageTooLarge
        }
        let base64 = data.base64EncodedString()
        var url = "data:image/jpeg;base64,"
        url.reserveCapacity(url.count + base64.count)
        url += base64
        return url
    }

    private static func encodedJPEGData(
        from image: UIImage
    ) throws -> Data {
        guard let plan = ImageEncodingPlanBuilder.aiImagePlan(
            imageSize: image.size
        ) else {
            throw AIServiceError.invalidImage
        }

        for maximumDimension in plan.maximumDimensions {
            let normalized = ImageRenderSupport.normalizedOpaqueImage(
                image,
                maximumDimension: maximumDimension
            )
            guard let data = ImageJPEGEncoder.adaptiveData(
                from: normalized,
                profile: plan.primaryProfile
            ) else {
                throw AIServiceError.invalidImage
            }
            if data.count <= plan.primaryProfile.maximumBytes {
                return data
            }
        }

        let fallback = ImageRenderSupport.normalizedOpaqueImage(
            image,
            maximumDimension: plan.fallbackMaximumDimension
        )
        guard let data = ImageJPEGEncoder.adaptiveData(
            from: fallback,
            profile: plan.fallbackProfile
        ) else {
            throw AIServiceError.invalidImage
        }
        guard data.count <= plan.fallbackProfile.maximumBytes else {
            throw AIServiceError.imageTooLarge
        }
        return data
    }
}
