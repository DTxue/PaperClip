import Foundation
import UIKit

extension AIService {
    static func generateWritingPrompt(
        language: WritingLanguage,
        studentGrade: String,
        requirementInput: String
    ) async throws -> AIWritingPromptResult {
        let requirement = requirementInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !requirement.isEmpty else {
            throw AIServiceError.invalidQuestion
        }

        let prompt = WritingPromptConfiguration.render(
            WritingPromptConfiguration.resolvedPrompt(for: .generation(for: language)),
            variables: [
                "studentGrade": studentGrade,
                "requirementInput": requirement
            ]
        )

        let configuration = AIRequestConfiguration.deepSeek(
            modelName: "DeepSeek 写作命题",
            maxOutputTokens: 4_096
        )
        return try await requestDecoded(
            AIWritingPromptResult.self,
            prompt,
            configuration: configuration
        )
    }

    static func recognizeWriting(
        image: UIImage,
        language: WritingLanguage
    ) async throws -> AIWritingRecognitionResult {
        let instruction = """
        请识别图片中的学生手写\(language.shortTitle)作文，只做转写，不要批改、不要润色、不要补写。

        规则：
        1. 尽量保留原文段落、换行、标点和大小写。
        2. 对明显无法确定的字词，可在原文中用 [?] 标注，并在 possibleIssues 中说明。
        3. 不要自动纠正错别字、拼写、语法或用词错误。
        4. 如果页面为空，recognizedText 返回空字符串。
        5. 只输出合法 JSON，不要输出 Markdown 或额外文字。

        JSON 结构：
        {
          "recognizedText": "识别出的作文原文",
          "possibleIssues": ["疑似识别不确定的位置"]
        }
        """
        let configuration = AIRequestConfiguration.doubao(
            modelName: "豆包作文识别",
            maxOutputTokens: 8_192
        )
        return try await requestDecoded(
            AIWritingRecognitionResult.self,
            content: try imageThenTextContent(image: image, text: instruction),
            configuration: configuration
        )
    }

    static func reviewWriting(
        language: WritingLanguage,
        studentGrade: String,
        writingRequirement: String,
        recognizedText: String,
        fullScore: Int? = nil
    ) async throws -> AIWritingReviewResult {
        let essay = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !essay.isEmpty else {
            throw AIServiceError.invalidQuestion
        }

        let prompt = WritingPromptConfiguration.render(
            WritingPromptConfiguration.resolvedPrompt(for: .review(for: language)),
            variables: [
                "studentGrade": studentGrade,
                "writingRequirement": writingRequirement,
                "recognizedText": essay,
                "fullScore": String(fullScore ?? language.defaultFullScore)
            ]
        )

        let configuration = AIRequestConfiguration.deepSeek(
            modelName: "DeepSeek 作文批阅",
            maxOutputTokens: 16_384
        )
        return try await requestDecoded(
            AIWritingReviewResult.self,
            prompt,
            configuration: configuration
        )
    }
}
