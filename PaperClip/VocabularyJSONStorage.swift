import Foundation

enum VocabularyJSONStorage {
    static func encode<T: Encodable>(_ value: T, fallback: String = "[]") -> String {
        guard let data = try? JSONEncoder().encode(value),
              let string = String(data: data, encoding: .utf8) else {
            return fallback
        }
        return string
    }

    static func decode<T: Decodable>(_ type: T.Type, from json: String, fallback: T) -> T {
        (try? JSONDecoder().decode(type, from: Data(json.utf8))) ?? fallback
    }

    static func decodeOptional<T: Decodable>(_ type: T.Type, from json: String) -> T? {
        try? JSONDecoder().decode(type, from: Data(json.utf8))
    }
}
