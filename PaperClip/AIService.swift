import Foundation

enum AIService {
    static let defaultDoubaoInferenceID = "ep-20260620182757-zwqg9"
    static let defaultDeepSeekInferenceID = "deepseek-v4-pro"

    static var isDeepSeekConfigured: Bool {
        !resolvedDeepSeekInferenceID().isEmpty
    }

    static func migratedDoubaoInferenceID(_ value: String?) -> String {
        AIModelRouting.migratedDoubaoInferenceID(
            value,
            defaultID: defaultDoubaoInferenceID
        )
    }
}
