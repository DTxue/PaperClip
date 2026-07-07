import Foundation

enum ReviewSubmissionGenerationFlow {
    static func generateImageData(for request: ReviewSubmissionGenerationRequest) async throws -> Data {
        try await Task.detached(priority: .userInitiated) {
            try ReviewSubmissionRenderer.render(request)
        }.value
    }
}
