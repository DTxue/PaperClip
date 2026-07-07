import Foundation

extension AIService {
    static func performArk(
        _ body: ResponsesRequest,
        apiKey: String,
        modelName: String
    ) async throws -> String {
        var request = URLRequest(url: arkEndpoint, timeoutInterval: 230)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let data = try await send(request, modelName: modelName, errorMessage: arkErrorMessage)

        let responseBody = try AIServiceErrorMessageSupport.decodeProviderResponse(
            ResponsesResponse.self,
            from: data,
            modelName: modelName
        )

        guard let content = responseBody.outputText?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else {
            throw AIServiceError.emptyResponse(modelName)
        }
        return content
    }

    private static let arkEndpoint = URL(
        string: "https://ark.cn-beijing.volces.com/api/v3/responses"
    )!

    private static func arkErrorMessage(from data: Data) -> String {
        AIServiceErrorMessageSupport.message(
            from: data,
            defaultMessage: "请检查 API Key、推理接入点和火山方舟服务状态。",
            decode: ArkErrorResponse.self
        ) { $0.error.message }
    }
}
