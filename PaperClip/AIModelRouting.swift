import Foundation

enum AIModelProvider {
    case doubao
    case deepSeek
}

enum AIModelRouting {
    static func migratedDoubaoInferenceID(
        _ value: String?,
        defaultID: String,
        legacyIDs: Set<String> = []
    ) -> String {
        guard let value else { return defaultID }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.lowercased()
        if normalized.isEmpty || legacyIDs.contains(normalized) {
            return defaultID
        }
        return trimmed
    }

    static func inferenceID(
        for model: AIAnswerModel,
        storedDoubaoID: String?,
        defaultDoubaoID: String,
        deepSeekID: String
    ) throws -> String {
        switch model {
        case .doubao:
            let migrated = migratedDoubaoInferenceID(
                storedDoubaoID,
                defaultID: defaultDoubaoID
            )
            guard !migrated.isEmpty else {
                throw AIServiceError.invalidModelID
            }
            return migrated
        case .deepSeek:
            let endpointID = deepSeekID.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !endpointID.isEmpty else {
                throw AIServiceError.missingDeepSeekEndpoint
            }
            return endpointID
        }
    }

    static func provider(
        for modelID: String,
        deepSeekID: String
    ) -> AIModelProvider {
        modelID == deepSeekID ? .deepSeek : .doubao
    }

    static func apiKey(
        _ value: String?,
        provider: AIModelProvider
    ) throws -> String {
        let apiKey = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !apiKey.isEmpty else {
            switch provider {
            case .doubao:
                throw AIServiceError.missingAPIKey
            case .deepSeek:
                throw AIServiceError.missingDeepSeekAPIKey
            }
        }
        return apiKey
    }
}
