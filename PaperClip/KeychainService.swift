import Foundation
import Security

enum KeychainKey: String {
    case doubaoAPIKey = "com.paperclip.doubao-api-key"
    case doubaoModelID = "com.paperclip.doubao-model-id"
    case deepSeekAPIKey = "com.paperclip.deepseek-api-key"
    case deepSeekModelID = "com.paperclip.deepseek-model-id"
    // 旧版本视觉接入点键仅用于首次读取迁移，新的 AI 实现不再写入。
    case doubaoVisionEndpoint = "com.paperclip.doubao-vision-endpoint"
}

enum KeychainService {
    static func save(_ value: String, for key: KeychainKey) {
        guard !value.isEmpty else {
            if load(for: key) != nil {
                delete(for: key)
            }
            return
        }

        if load(for: key) == value { return }

        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue
        ]
        let attributes: [CFString: Any] = [
            kSecValueData: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insertQuery = query
            insertQuery[kSecValueData] = data
            SecItemAdd(insertQuery as CFDictionary, nil)
        }
    }

    static func load(for key: KeychainKey) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(for key: KeychainKey) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue
        ]
        SecItemDelete(query as CFDictionary)
    }
}
