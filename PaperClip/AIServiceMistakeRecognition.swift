import UIKit

extension AIService {
    static func recognizeMistakeImages(
        _ images: [UIImage]
    ) async throws -> AIMistakeRecognitionResult {
        guard !images.isEmpty else {
            throw AIServiceError.invalidImage
        }
        var content = try images.map { try imageContent(from: $0) }
        content.append(.text(MistakeRecognitionPrompt.instruction))
        return try await requestDecoded(
            AIMistakeRecognitionResult.self,
            content: content,
            configuration: .doubao(
                modelName: "豆包错题识别",
                maxOutputTokens: 8_192
            )
        )
    }
}
