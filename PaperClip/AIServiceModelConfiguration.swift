import Foundation

extension AIService {
    static func inferenceID(for model: AIAnswerModel) throws -> String {
        switch model {
        case .doubao:
            return try resolvedDoubaoInferenceID()
        case .deepSeek:
            return try AIModelRouting.inferenceID(
                for: .deepSeek,
                storedDoubaoID: nil,
                defaultDoubaoID: defaultDoubaoInferenceID,
                deepSeekID: resolvedDeepSeekInferenceID()
            )
        }
    }

    static func resolvedDeepSeekInferenceID() -> String {
        defaultDeepSeekInferenceID
    }

    static func resolvedDoubaoInferenceID() throws -> String {
        let stored = storedDoubaoInferenceID()
        let migrated = migratedDoubaoInferenceID(stored)
        if migrated != stored {
            KeychainService.save(migrated, for: .doubaoModelID)
        }
        return try AIModelRouting.inferenceID(
            for: .doubao,
            storedDoubaoID: migrated,
            defaultDoubaoID: defaultDoubaoInferenceID,
            deepSeekID: resolvedDeepSeekInferenceID()
        )
    }

    static func storedDoubaoInferenceID() -> String {
        let stored = KeychainService.load(for: .doubaoModelID)
            ?? KeychainService.load(for: .doubaoVisionEndpoint)
        return stored?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? defaultDoubaoInferenceID
    }

    static func resolvedAPIKey(for model: String) throws -> String {
        let provider = AIModelRouting.provider(
            for: model,
            deepSeekID: resolvedDeepSeekInferenceID()
        )
        let key: KeychainKey = provider == .deepSeek ? .deepSeekAPIKey : .doubaoAPIKey
        return try AIModelRouting.apiKey(
            KeychainService.load(for: key),
            provider: provider
        )
    }
}
