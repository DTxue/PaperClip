import Foundation

extension WritingPromptConfiguration {
    static let defaultChineseGenerationPrompt = loadDefaultPrompt(
        resourceName: "chinese-generation",
        fallback: """
        你是写作命题助手。请根据用户输入，为学生生成一个清晰、可操作、有训练价值的中文作文题。
        """
    )

    static let defaultEnglishGenerationPrompt = loadDefaultPrompt(
        resourceName: "english-generation",
        fallback: """
        You are an advanced writing coach. Generate a writing prompt/topic for a student based on their grade and optional user inputs.
        """
    )

    static let defaultChineseReviewPrompt = loadDefaultPrompt(
        resourceName: "chinese-review",
        fallback: """
        你是一位高级写作指导教师，长期辅导高年级作文和高阶写作表达。
        """
    )

    static let defaultEnglishReviewPrompt = loadDefaultPrompt(
        resourceName: "english-review",
        fallback: """
        You are an advanced writing coach. Review the student's English composition and help the student improve vocabulary, spelling, grammar, sentence patterns, organization, and higher-level expression.
        """
    )

    private static func loadDefaultPrompt(resourceName: String, fallback: String) -> String {
        guard let url = Bundle.main.url(
            forResource: resourceName,
            withExtension: "txt",
            subdirectory: "WritingPrompts"
        ) ?? Bundle.main.url(forResource: resourceName, withExtension: "txt"),
        let text = try? String(contentsOf: url, encoding: .utf8) else {
            return fallback
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
