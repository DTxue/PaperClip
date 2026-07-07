import Foundation
import UIKit

extension AIService {
    static func recognize(image: UIImage) async throws -> AIQuestionRecognition {
        let configuration = AIRequestConfiguration.doubao(
            modelName: "豆包识别",
            maxOutputTokens: 4_096
        )
        return try await requestDecoded(
            AIQuestionRecognition.self,
            content: try imageThenTextContent(
                image: image,
                text: AIRecognitionPrompt.instructions
            ),
            configuration: configuration
        )
    }

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

    static func solve(
        question: String,
        recognition: AIQuestionRecognition,
        using model: AIAnswerModel
    ) async throws -> AIQuestionSolution {
        let confirmedQuestion = question.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !confirmedQuestion.isEmpty else {
            throw AIServiceError.invalidQuestion
        }

        let configuration = AIRequestConfiguration.answer(model: model)
        return try await requestDecoded(
            AIQuestionSolution.self,
            content: [
                .text(
                    AISolutionPrompt.instructions(
                        question: confirmedQuestion,
                        recognition: recognition
                    )
                )
            ],
            configuration: configuration
        )
    }
}
