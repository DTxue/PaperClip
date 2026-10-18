import Foundation
import UIKit

extension AIService {
    static func splitCard(term: String, definition: String) async throws -> VocabularyCardSplitResult {
        let configuration = AIRequestConfiguration.doubao(
            modelName: "豆包拆分",
            maxOutputTokens: 1_024
        )
        return try await requestDecoded(
            VocabularyCardSplitResult.self,
            VocabularyAIPrompts.splitCard(term: term, definition: definition),
            configuration: configuration
        )
    }

    static func generateDistractors(
        term: String,
        definition: String,
        partOfSpeech: String,
        example: String,
        config: DistractorConfig = DistractorConfig()
    ) async throws -> VocabularyDistractorResult {
        let configuration = AIRequestConfiguration.doubao(
            modelName: "豆包词库",
            maxOutputTokens: 512
        )
        return try await requestDecoded(
            VocabularyDistractorResult.self,
            VocabularyAIPrompts.distractors(
                term: term,
                definition: definition,
                partOfSpeech: partOfSpeech,
                example: example,
                config: config
            ),
            configuration: configuration
        )
    }

    static func generateEnglishDefinitions(
        cards: [VocabularyEnglishDefinitionInput]
    ) async throws -> [VocabularyGeneratedEnglishDefinition] {
        guard !cards.isEmpty else { return [] }

        let configuration = AIRequestConfiguration.deepSeek(
            modelName: AIService.defaultDeepSeekInferenceID,
            maxOutputTokens: 4_000
        )
        let result = try await requestDecoded(
            VocabularyEnglishDefinitionGenerationResult.self,
            VocabularyAIPrompts.englishDefinitions(cards: cards),
            configuration: configuration
        )

        var generated: [VocabularyGeneratedEnglishDefinition] = []
        generated.reserveCapacity(cards.count)
        for item in result.items {
            let cardIndex = item.index - 1
            guard cards.indices.contains(cardIndex) else { continue }
            let definition = item.englishDefinition
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !definition.isEmpty else { continue }
            generated.append(VocabularyGeneratedEnglishDefinition(
                cardID: cards[cardIndex].cardID,
                englishDefinition: definition
            ))
        }
        return generated
    }

    static func recognizeVocabularyHandwriting(
        handwritingImages: [UIImage?],
        isChinese: Bool
    ) async throws -> VocabularyGradingResult {
        let count = handwritingImages.count
        guard count > 0 else {
            return VocabularyGradingResult(items: [])
        }

        var contentItems: [ResponsesRequest.Content] = []
        contentItems.reserveCapacity(count * 2 + 1)
        for i in 0 ..< count {
            contentItems.append(.text(
                VocabularyAIPrompts.handwritingRecognitionQuestionText(
                    index: i,
                    hasAnswer: handwritingImages[i] != nil
                )
            ))
            if let image = handwritingImages[i] {
                contentItems.append(try imageContent(from: image))
            }
        }
        contentItems.append(.text(VocabularyAIPrompts.handwritingRecognitionInstruction(
            count: count,
            isChinese: isChinese
        )))

        let configuration = AIRequestConfiguration.doubao(
            modelName: "豆包手写识别",
            maxOutputTokens: VocabularyGradingOutputBudget.maxTokens(questionCount: count)
        )
        return try await requestDecoded(
            VocabularyGradingResult.self,
            content: contentItems,
            configuration: configuration
        )
    }

    static func recognizeChineseHandwrittenCharacter(image: UIImage) async throws -> String {
        let content: [ResponsesRequest.Content] = [
            .text("识别这张单格图片中的一个手写汉字或标点。"),
            try imageContent(from: image),
            .text(VocabularyAIPrompts.chineseCharacterRecognitionInstruction())
        ]
        let configuration = AIRequestConfiguration.doubao(
            modelName: "豆包单字手写识别",
            maxOutputTokens: VocabularyGradingOutputBudget.maxTokens(questionCount: 1)
        )
        let result = try await requestDecoded(
            VocabularyGradingResult.self,
            content: content,
            configuration: configuration
        )
        guard result.items.count == 1,
              let recognized = result.items.first?.recognizedText else {
            return "�"
        }
        let character = recognized.trimmingCharacters(in: .whitespacesAndNewlines)
        return character.count == 1 ? character : "�"
    }
}
