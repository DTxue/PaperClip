import Foundation

enum AIService {
    static let defaultDoubaoInferenceID = "doubao-seed-2-1-pro-260628"
    static let defaultDeepSeekInferenceID = "deepseek-v4-pro"

    private static let legacyDoubaoInferenceIDs: Set<String> = [
        "doubao-vision-pro",
        "ep-20260620182757-zwqg9"
    ]

    static func migratedDoubaoInferenceID(_ value: String?) -> String {
        AIModelRouting.migratedDoubaoInferenceID(
            value,
            defaultID: defaultDoubaoInferenceID,
            legacyIDs: legacyDoubaoInferenceIDs
        )
    }
}
