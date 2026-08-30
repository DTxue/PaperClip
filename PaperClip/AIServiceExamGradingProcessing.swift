import Foundation

extension AIService {
    static func gradeExam(pageJPEGData: [Data]) async throws -> AIExamGradingResult {
        guard !pageJPEGData.isEmpty else {
            throw AIServiceError.invalidImage
        }

        var contentItems: [ResponsesRequest.Content] = []
        contentItems.reserveCapacity(pageJPEGData.count * 2 + 1)
        for (index, data) in pageJPEGData.enumerated() {
            contentItems.append(.text("第 \(index) 页，pageIndex 必须返回 \(index)。"))
            contentItems.append(try imageContent(fromJPEGData: data))
        }
        contentItems.append(.text(AIExamGradingPrompt.instructions(pageCount: pageJPEGData.count)))

        let configuration = AIRequestConfiguration.doubao(
            modelName: "豆包交卷批阅",
            maxOutputTokens: 4_096
        )
        return try await requestDecoded(
            AIExamGradingResult.self,
            content: contentItems,
            configuration: configuration
        )
    }

    static func gradeExamPage(jpegData: Data) async throws -> AIExamGradingResult {
        try await gradeExam(pageJPEGData: [jpegData])
    }
}
