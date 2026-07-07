import CoreGraphics

struct ImageEncodingPlan: Equatable {
    let maximumDimensions: [CGFloat]
    let primaryProfile: ImageJPEGProfile
    let fallbackMaximumDimension: CGFloat
    let fallbackProfile: ImageJPEGProfile
}

struct ImageEncodingPolicy: Equatable {
    let maximumDimension: CGFloat
    let fallbackDimensions: [CGFloat]
    let fallbackMaximumDimension: CGFloat
    let primaryProfile: ImageJPEGProfile
    let fallbackProfile: ImageJPEGProfile

    static let aiRequest = ImageEncodingPolicy(
        maximumDimension: 2_200,
        fallbackDimensions: [1_800, 1_500, 1_200],
        fallbackMaximumDimension: 1_000,
        primaryProfile: .aiRequest,
        fallbackProfile: .aiRequestFallback
    )
}

enum ImageEncodingPlanBuilder {
    static func aiImagePlan(
        imageSize: CGSize,
        policy: ImageEncodingPolicy = .aiRequest
    ) -> ImageEncodingPlan? {
        guard imageSize.width > 0,
              imageSize.height > 0,
              policy.maximumDimension > 0,
              policy.fallbackMaximumDimension > 0,
              isValidProfile(policy.primaryProfile),
              isValidProfile(policy.fallbackProfile)
        else { return nil }

        return ImageEncodingPlan(
            maximumDimensions: dimensionCandidates(
                longestSide: max(imageSize.width, imageSize.height),
                maximumDimension: policy.maximumDimension,
                fallbackDimensions: policy.fallbackDimensions
            ),
            primaryProfile: policy.primaryProfile,
            fallbackMaximumDimension: policy.fallbackMaximumDimension,
            fallbackProfile: policy.fallbackProfile
        )
    }

    static func dimensionCandidates(
        longestSide: CGFloat,
        maximumDimension: CGFloat,
        fallbackDimensions: [CGFloat]
    ) -> [CGFloat] {
        guard longestSide > 0, maximumDimension > 0 else { return [] }

        var candidates: [CGFloat] = []
        candidates.reserveCapacity(fallbackDimensions.count + 1)
        var seen = Set<Int>()
        for dimension in [maximumDimension] + fallbackDimensions {
            let target = min(dimension, longestSide).rounded()
            guard target > 0 else { continue }
            let key = Int(target)
            guard seen.insert(key).inserted else { continue }
            candidates.append(target)
        }
        return candidates
    }

    private static func isValidProfile(_ profile: ImageJPEGProfile) -> Bool {
        profile.maximumBytes > 0
            && !profile.qualities.isEmpty
            && profile.qualities.allSatisfy { $0 > 0 && $0 <= 1 }
    }
}
