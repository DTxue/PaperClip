import Foundation

extension AIService {
    static func generateVocabularyContextPractice(
        cards: [VocabularyContextCardInput],
        configuration: VocabularyContextPromptConfiguration
    ) async throws -> VocabularyContextPracticeLesson {
        let requestConfiguration = AIRequestConfiguration.deepSeek(
            modelName: AIService.defaultDeepSeekInferenceID,
            maxOutputTokens: min(4_096, max(1_024, cards.count * 420))
        )
        var prompt = VocabularyContextPracticePrompt.make(
            cards: cards,
            configuration: configuration
        )
        var lastValidationError: VocabularyContextPracticeValidationError?

        for attempt in 0..<2 {
            let generated = try await requestDecoded(
                VocabularyContextGenerationResult.self,
                prompt,
                configuration: requestConfiguration
            )
            do {
                return try VocabularyContextPracticeBuilder.build(
                    cards: cards,
                    generated: generated,
                    maximumSentenceWords: configuration.maximumSentenceWords
                )
            } catch let error as VocabularyContextPracticeValidationError {
                lastValidationError = error
                guard attempt == 0 else { break }
                prompt = VocabularyContextPracticePrompt.revision(
                    cards: cards,
                    configuration: configuration,
                    issues: error.issues
                )
            }
        }

        throw lastValidationError ?? VocabularyContextPracticeValidationError(
            issues: ["AI 没有返回可用的语境练习。"]
        )
    }
}
