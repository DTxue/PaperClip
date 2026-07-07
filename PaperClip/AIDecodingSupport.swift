import Foundation

enum AIResponseDecodingSupport {
    enum DecodingFailure: Error {
        case invalidUTF8
    }

    static func sanitizedJSONValue(from content: String) -> String {
        AIResponseJSONSanitizer.sanitizedJSONValue(from: content)
    }

    static func decodedJSONValue<T: Decodable>(
        _ type: T.Type,
        from content: String,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase
    ) throws -> T {
        let json = sanitizedJSONValue(from: content)
        guard let data = json.data(using: .utf8) else {
            throw DecodingFailure.invalidUTF8
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        return try decoder.decode(type, from: data)
    }
}

extension KeyedDecodingContainer {
    func decodeString(_ key: Key, fallback: String = "") -> String {
        if let value = try? decode(String.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decode(Double.self, forKey: key) {
            return String(value)
        }
        return fallback
    }

    func decodeStringArray(_ key: Key) -> [String] {
        if let value = try? decode([String].self, forKey: key) {
            return value
        }
        if let value = try? decode(String.self, forKey: key), !value.isEmpty {
            return value
                .split(whereSeparator: \.isNewline)
                .map(String.init)
                .filter { !$0.isEmpty }
        }
        return []
    }

    func decodeArray<T: Decodable>(_ type: [T].Type, _ key: Key) -> [T] {
        (try? decode(type, forKey: key)) ?? []
    }

    func decodeFlexibleDouble(_ key: Key) -> Double {
        if let value = try? decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return Double(value)
        }
        if let value = try? decode(String.self, forKey: key) {
            return Double(value.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        }
        return 0
    }

    func decodeFlexibleInt(_ key: Key) -> Int {
        if let value = try? decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? decode(Double.self, forKey: key) {
            return Int(value)
        }
        if let value = try? decode(String.self, forKey: key) {
            return Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        }
        return 0
    }
}
