import Foundation

enum AIServiceErrorMessageSupport {
    static func decodeProviderResponse<Response: Decodable>(
        _ responseType: Response.Type,
        from data: Data,
        modelName: String
    ) throws -> Response {
        do {
            return try JSONDecoder().decode(responseType, from: data)
        } catch {
            throw AIServiceError.malformedResponse(
                modelName,
                responseSnippet(from: data, fallback: error.localizedDescription)
            )
        }
    }

    static func message<Response: Decodable>(
        from data: Data,
        defaultMessage: String,
        decode responseType: Response.Type,
        extractMessage: (Response) -> String?
    ) -> String {
        if let response = try? JSONDecoder().decode(responseType, from: data),
           let message = extractMessage(response)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !message.isEmpty {
            return String(message.prefix(500))
        }
        if let body = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !body.isEmpty {
            return String(body.prefix(500))
        }
        return defaultMessage
    }

    private static func responseSnippet(from data: Data, fallback: String, limit: Int = 400) -> String {
        String(
            (String(data: data, encoding: .utf8) ?? fallback)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(limit)
        )
    }
}
