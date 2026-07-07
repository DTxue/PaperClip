import Foundation
import UIKit

extension VocabularyArticleCardInput {
    init(card: VocabularyCard) {
        self.init(
            term: card.term,
            definition: card.definition,
            phonetic: card.phonetic,
            example: card.example,
            partOfSpeech: card.partOfSpeech,
            tagsText: card.tagsText,
            note: card.note,
            alternativeAnswersText: card.alternativeAnswersText
        )
    }
}

extension AIService {
    static func generateVocabularyArticle(cards: [VocabularyArticleCardInput]) async throws -> VocabularyArticleDraft {
        let configuration = AIRequestConfiguration.deepSeek(
            modelName: AIService.defaultDeepSeekInferenceID,
            maxOutputTokens: 12_000
        )
        let result = try await requestDecoded(
            VocabularyArticleGenerationResult.self,
            VocabularyAIPrompts.article(cards: cards),
            configuration: configuration
        )
        let title = result.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return VocabularyArticleDraft(
            title: title.isEmpty ? "Vocabulary Story" : title,
            articleText: result.article.trimmingCharacters(in: .whitespacesAndNewlines),
            coveredTerms: result.coveredTerms,
            sourceCardSnapshotHash: VocabularyArticleSourceFingerprint.make(cards: cards),
            modelName: AIService.defaultDeepSeekInferenceID,
            promptVersion: 1
        )
    }

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

    static func gradeVocabularyTest(
        cards: [(term: String, definition: String)],
        handwritingImages: [UIImage?]
    ) async throws -> VocabularyGradingResult {
        let count = min(cards.count, handwritingImages.count)
        guard count > 0 else {
            return VocabularyGradingResult(items: [])
        }

        var contentItems: [ResponsesRequest.Content] = []
        contentItems.reserveCapacity(count * 2 + 1)
        for i in 0 ..< count {
            let card = cards[i]
            let hasAnswer = handwritingImages[i] != nil
            contentItems.append(.text(
                VocabularyAIPrompts.gradingQuestionText(
                    index: i,
                    term: card.term,
                    definition: card.definition,
                    hasAnswer: hasAnswer
                )
            ))
            if let image = handwritingImages[i] {
                contentItems.append(try imageContent(from: image))
            }
        }
        contentItems.append(.text(VocabularyAIPrompts.gradingInstruction(count: count)))

        let configuration = AIRequestConfiguration.doubao(
            modelName: "豆包批改",
            maxOutputTokens: 512
        )
        return try await requestDecoded(
            VocabularyGradingResult.self,
            content: contentItems,
            configuration: configuration
        )
    }
}
