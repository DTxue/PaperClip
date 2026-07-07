import Foundation

enum WritingReviewJSONStorage {
    static func encode(_ result: AIWritingReviewResult) -> Data {
        (try? JSONEncoder().encode(result)) ?? Data()
    }

    static func decode(_ data: Data) -> AIWritingReviewResult? {
        try? JSONDecoder().decode(AIWritingReviewResult.self, from: data)
    }
}
