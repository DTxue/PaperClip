import Foundation

enum WritingPromptConfiguration: String, Identifiable {
    case chineseGeneration
    case englishGeneration
    case chineseReview
    case englishReview

    /// 设置界面只展示当前开放的中文写作提示词。
    static let availableCases: [WritingPromptConfiguration] = [
        .chineseGeneration,
        .chineseReview
    ]

    var id: Self { self }

    var title: String {
        switch self {
        case .chineseGeneration: "中文命题提示词"
        case .englishGeneration: "英文命题提示词"
        case .chineseReview: "中文批阅提示词"
        case .englishReview: "英文批阅提示词"
        }
    }

    var storageKey: String {
        "writing.prompt.\(rawValue)"
    }

    var defaultValue: String {
        switch self {
        case .chineseGeneration:
            Self.defaultChineseGenerationPrompt
        case .englishGeneration:
            Self.defaultEnglishGenerationPrompt
        case .chineseReview:
            Self.defaultChineseReviewPrompt
        case .englishReview:
            Self.defaultEnglishReviewPrompt
        }
    }

    static func generation(for language: WritingLanguage) -> Self {
        switch language {
        case .chinese: .chineseGeneration
        case .english: .englishGeneration
        }
    }

    static func review(for language: WritingLanguage) -> Self {
        switch language {
        case .chinese: .chineseReview
        case .english: .englishReview
        }
    }

    static func resolvedPrompt(for kind: WritingPromptConfiguration) -> String {
        let stored = UserDefaults.standard.string(forKey: kind.storageKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return stored.flatMap { $0.isEmpty ? nil : $0 } ?? kind.defaultValue
    }

    @discardableResult
    static func save(_ prompt: String, for kind: WritingPromptConfiguration) -> Bool {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentValue = UserDefaults.standard.string(forKey: kind.storageKey)
        if trimmed.isEmpty || trimmed == kind.defaultValue {
            guard currentValue != nil else { return false }
            UserDefaults.standard.removeObject(forKey: kind.storageKey)
            return true
        } else if currentValue == trimmed {
            return false
        } else {
            UserDefaults.standard.set(trimmed, forKey: kind.storageKey)
            return true
        }
    }

    static func render(_ template: String, variables: [String: String]) -> String {
        variables.reduce(template) { result, pair in
            result.replacingOccurrences(of: "{\(pair.key)}", with: pair.value)
        }
    }
}
