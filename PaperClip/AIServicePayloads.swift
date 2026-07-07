import Foundation

struct ResponsesRequest: Encodable, Sendable {
    struct Input: Encodable, Sendable {
        let role: String
        let content: [Content]
    }

    enum Content: Encodable, Sendable {
        case image(url: String)
        case text(String)

        private enum CodingKeys: String, CodingKey {
            case type
            case imageURL = "image_url"
            case text
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .image(let url):
                try container.encode("input_image", forKey: .type)
                try container.encode(url, forKey: .imageURL)
            case .text(let text):
                try container.encode("input_text", forKey: .type)
                try container.encode(text, forKey: .text)
            }
        }
    }

    struct Thinking: Encodable, Sendable {
        let type: String
    }

    private enum CodingKeys: String, CodingKey {
        case model, input, thinking, stream
        case maxOutputTokens = "max_output_tokens"
    }

    let model: String
    let input: [Input]
    let thinking: Thinking
    let stream: Bool
    let maxOutputTokens: Int

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(model, forKey: .model)
        try c.encode(input, forKey: .input)
        try c.encode(thinking, forKey: .thinking)
        try c.encode(stream, forKey: .stream)
        try c.encode(maxOutputTokens, forKey: .maxOutputTokens)
    }
}
