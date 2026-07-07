import CoreGraphics
import Foundation

private func expect(
    _ condition: @autoclosure () -> Bool,
    _ message: String,
    file: StaticString = #file,
    line: UInt = #line
) {
    guard condition() else {
        fatalError(message, file: file, line: line)
    }
}

@main
enum ImageEncodingPlanTests {
    static func main() {
        testAIImagePlanBuildsDeduplicatedDimensionFallbacks()
        testAIRequestPolicyKeepsExistingDimensionsAndProfiles()
        testAIImagePlanDoesNotUpscaleSmallImages()
        testAIImagePlanRejectsInvalidInputs()

        print("ImageEncodingPlanTests: 4 passed")
    }

    private static func testAIImagePlanBuildsDeduplicatedDimensionFallbacks() {
        let plan = ImageEncodingPlanBuilder.aiImagePlan(
            imageSize: CGSize(width: 4_000, height: 3_000),
            policy: ImageEncodingPolicy(
                maximumDimension: 2_200,
                fallbackDimensions: [1_800, 1_800, 1_500, 1_200],
                fallbackMaximumDimension: 1_000,
                primaryProfile: .aiRequest,
                fallbackProfile: .aiRequestFallback
            )
        )

        expect(plan != nil, "valid image size should produce an encoding plan")
        expect(plan!.maximumDimensions == [2_200, 1_800, 1_500, 1_200], "dimensions should preserve order and remove duplicates")
        expect(plan!.primaryProfile == .aiRequest, "primary AI image profile should preserve existing JPEG settings")
        expect(plan!.fallbackMaximumDimension == 1_000, "fallback dimension should preserve the default")
        expect(plan!.fallbackProfile == .aiRequestFallback, "fallback AI image profile should preserve the default")
    }

    private static func testAIRequestPolicyKeepsExistingDimensionsAndProfiles() {
        let policy = ImageEncodingPolicy.aiRequest

        expect(policy.maximumDimension == 2_200, "AI request primary dimension should be 2200")
        expect(policy.fallbackDimensions == [1_800, 1_500, 1_200], "AI request fallback dimensions should preserve order")
        expect(policy.fallbackMaximumDimension == 1_000, "AI request final fallback dimension should be 1000")
        expect(policy.primaryProfile == .aiRequest, "AI request policy should use the AI JPEG profile")
        expect(policy.fallbackProfile == .aiRequestFallback, "AI request policy should use the fallback AI JPEG profile")
    }

    private static func testAIImagePlanDoesNotUpscaleSmallImages() {
        let dimensions = ImageEncodingPlanBuilder.dimensionCandidates(
            longestSide: 1_240.4,
            maximumDimension: 2_200,
            fallbackDimensions: [1_800, 1_500, 1_200]
        )

        expect(dimensions == [1_240, 1_200], "small images should cap candidates at the original longest side")
    }

    private static func testAIImagePlanRejectsInvalidInputs() {
        expect(
            ImageEncodingPlanBuilder.aiImagePlan(
                imageSize: .zero
            ) == nil,
            "empty images should be rejected"
        )
        expect(
            ImageEncodingPlanBuilder.dimensionCandidates(
                longestSide: 0,
                maximumDimension: 2_200,
                fallbackDimensions: [1_800]
            ).isEmpty,
            "empty dimensions should produce no candidates"
        )
    }

}
