import Foundation

extension AIService {
    struct ExtractedItem: Decodable {
        let text: String
        let change: String?
    }

    static func extractKnowledgeItems(from text: String, source: String) async throws -> [ExtractedItem] {
        let diaryModel = resolvedDiaryModel()
        let configuration = AIRequestConfiguration.knowledge(
            model: diaryModel,
            taskName: "知识提取"
        )
        let content = try await requestText(
            KnowledgeAIPrompts.extract(text: text, source: source),
            configuration: configuration
        )
        return try decode(
            [ExtractedItem].self,
            from: content,
            modelName: configuration.modelName
        )
    }

    static func analyzeKnowledgeItem(_ summary: String) async throws -> KnowledgeAnalysis {
        let diaryModel = resolvedDiaryModel()
        let configuration = AIRequestConfiguration.knowledge(
            model: diaryModel,
            taskName: "知识解析"
        )
        let result = try await requestDecoded(
            KnowledgeAnalysisDecodable.self,
            KnowledgeAIPrompts.analyze(summary),
            configuration: configuration
        )
        return result.toAnalysis()
    }

    static func resolvedDiaryModel() -> AIAnswerModel {
        let raw = UserDefaults.standard.string(forKey: "diaryAIModel") ?? ""
        return AIAnswerModel(rawValue: raw) ?? .doubao
    }

}
