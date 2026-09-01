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
enum ImageJPEGProfileTests {
    static func main() {
        testAIRequestProfilesKeepExistingBudgetAndQualities()
        testProfilesKeepDescendingQualityOrder()

        print("ImageJPEGProfileTests: 2 passed")
    }

    private static func testAIRequestProfilesKeepExistingBudgetAndQualities() {
        expect(ImageJPEGProfile.aiRequest.maximumBytes == 8 * 1024 * 1024, "AI image budget should be 8MB")
        expect(
            ImageJPEGProfile.aiRequest.qualities == [0.82, 0.74, 0.66, 0.58],
            "AI image qualities should preserve the existing sequence"
        )
        expect(
            ImageJPEGProfile.aiRequestFallback == ImageJPEGProfile(
                maximumBytes: ImageJPEGProfile.aiRequest.maximumBytes,
                qualities: [0.5]
            ),
            "AI image fallback should reuse the same byte budget with the fallback quality"
        )
    }

    private static func testProfilesKeepDescendingQualityOrder() {
        for profile in [ImageJPEGProfile.aiRequest, .aiRequestFallback] {
            expect(!profile.qualities.isEmpty, "profile should provide at least one quality")
            expect(
                profile.qualities.allSatisfy { $0 > 0 && $0 <= 1 },
                "qualities should be valid JPEG compression values"
            )
            expect(
                profile.qualities == profile.qualities.sorted(by: >),
                "adaptive JPEG qualities should try higher quality before lower quality"
            )
        }
    }
}
