import Foundation

extension AIService {
    static func performDeepSeek(
        _ body: ResponsesRequest,
        apiKey: String,
        modelName: String
    ) async throws -> String {
        let url = URL(string: "https://api.deepseek.com/chat/completions")!
        var request = URLRequest(url: url, timeoutInterval: 230)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        request.httpBody = try JSONEncoder().encode(deepSeekRequest(from: body))

        let data = try await send(request, modelName: modelName, errorMessage: deepSeekErrorMessage)

        let responseBody = try AIServiceErrorMessageSupport.decodeProviderResponse(
            DeepSeekChatResponse.self,
            from: data,
            modelName: modelName
        )

        guard let content = responseBody.choices?.first?.message?.content?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else {
            throw AIServiceError.emptyResponse(modelName)
        }
        return content
    }

    private static func deepSeekRequest(from body: ResponsesRequest) -> DeepSeekChatRequest {
        let messages = body.input.map { input in
            let text = input.content.compactMap { content -> String? in
                if case .text(let value) = content { return value }
                return nil
            }.joined(separator: "\n")
            return DeepSeekChatRequest.Message(role: input.role, content: text)
        }
        return DeepSeekChatRequest(
            model: body.model,
            messages: messages,
            stream: false,
            maxTokens: body.maxOutputTokens
        )
    }

    private static func deepSeekErrorMessage(from data: Data) -> String {
        AIServiceErrorMessageSupport.message(
            from: data,
            defaultMessage: "请检查 API Key、模型名称和网络连接。",
            decode: DeepSeekErrorResponse.self
        ) { $0.error?.message }
    }
}
