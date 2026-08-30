import Foundation

struct AIServiceResponse<Value: Sendable>: Sendable {
    let value: Value
    let providerModelID: String?
}

struct ResponsesResponse: Decodable {
    struct OutputItem: Decodable {
        struct Content: Decodable {
            let type: String?
            let text: String?
        }

        let type: String?
        let content: [Content]?
    }

    let model: String?
    let output: [OutputItem]
    let outputTextValue: String?

    enum CodingKeys: String, CodingKey {
        case model, output
        case outputTextValue = "output_text"
    }

    var outputText: String? {
        if let outputTextValue, !outputTextValue.isEmpty {
            return outputTextValue
        }
        for item in output where item.type == nil || item.type == "message" {
            guard let content = item.content else { continue }
            for contentItem in content
                where contentItem.type == nil
                    || contentItem.type == "output_text"
                    || contentItem.type == "text" {
                if let text = contentItem.text {
                    return text
                }
            }
        }
        return nil
    }
}
