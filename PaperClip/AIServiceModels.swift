import Foundation

enum AIAnswerModel: String, CaseIterable, Identifiable, Sendable {
    case doubao
    case deepSeek

    var id: Self { self }

    var title: String {
        switch self {
        case .doubao: "豆包 Seed 2.1 Pro"
        case .deepSeek: "DeepSeek V4 Pro"
        }
    }

    var shortTitle: String {
        switch self {
        case .doubao: "豆包"
        case .deepSeek: "DeepSeek"
        }
    }

    var systemImage: String {
        switch self {
        case .doubao: "bolt.fill"
        case .deepSeek: "brain.head.profile"
        }
    }

    var summary: String {
        switch self {
        case .doubao: "多模态理解"
        case .deepSeek: "深度推理"
        }
    }
}

struct AIRequestConfiguration: Equatable {
    let model: AIAnswerModel
    let thinking: String
    let maxOutputTokens: Int
    let modelName: String

    var usesDeepThinking: Bool {
        thinking == "enabled"
    }

    static func diary(model: AIAnswerModel) -> AIRequestConfiguration {
        AIRequestConfiguration(
            model: model,
            thinking: model == .deepSeek ? "enabled" : "disabled",
            maxOutputTokens: model == .deepSeek ? 4_096 : 2_048,
            modelName: "\(model.shortTitle)日记"
        )
    }

    static func knowledge(model: AIAnswerModel, taskName: String) -> AIRequestConfiguration {
        AIRequestConfiguration(
            model: model,
            thinking: "disabled",
            maxOutputTokens: 2_048,
            modelName: "\(model.shortTitle)\(taskName)"
        )
    }

    static func deepSeek(modelName: String, maxOutputTokens: Int) -> AIRequestConfiguration {
        AIRequestConfiguration(
            model: .deepSeek,
            thinking: "enabled",
            maxOutputTokens: maxOutputTokens,
            modelName: modelName
        )
    }

    static func doubao(modelName: String, maxOutputTokens: Int) -> AIRequestConfiguration {
        AIRequestConfiguration(
            model: .doubao,
            thinking: "disabled",
            maxOutputTokens: maxOutputTokens,
            modelName: modelName
        )
    }
}
