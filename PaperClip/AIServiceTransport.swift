import Foundation

extension AIService {
    static func requestText(
        _ prompt: String,
        configuration: AIRequestConfiguration
    ) async throws -> String {
        try await requestText(
            prompt,
            model: try inferenceID(for: configuration.model),
            thinking: configuration.thinking,
            maxOutputTokens: configuration.maxOutputTokens,
            modelName: configuration.modelName
        )
    }

    static func requestText(
        _ prompt: String,
        model: String,
        thinking: String,
        maxOutputTokens: Int,
        modelName: String
    ) async throws -> String {
        try await requestContent(
            [.text(prompt)],
            model: model,
            thinking: thinking,
            maxOutputTokens: maxOutputTokens,
            modelName: modelName
        )
    }

    static func requestContent(
        _ content: [ResponsesRequest.Content],
        configuration: AIRequestConfiguration
    ) async throws -> String {
        try await requestContentResponse(
            content,
            model: try inferenceID(for: configuration.model),
            thinking: configuration.thinking,
            maxOutputTokens: configuration.maxOutputTokens,
            modelName: configuration.modelName
        ).value
    }

    static func requestContent(
        _ content: [ResponsesRequest.Content],
        model: String,
        thinking: String,
        maxOutputTokens: Int,
        modelName: String
    ) async throws -> String {
        try await requestContentResponse(
            content,
            model: model,
            thinking: thinking,
            maxOutputTokens: maxOutputTokens,
            modelName: modelName
        ).value
    }

    static func requestContentResponse(
        _ content: [ResponsesRequest.Content],
        configuration: AIRequestConfiguration
    ) async throws -> AIServiceResponse<String> {
        try await requestContentResponse(
            content,
            model: try inferenceID(for: configuration.model),
            thinking: configuration.thinking,
            maxOutputTokens: configuration.maxOutputTokens,
            modelName: configuration.modelName
        )
    }

    private static func requestContentResponse(
        _ content: [ResponsesRequest.Content],
        model: String,
        thinking: String,
        maxOutputTokens: Int,
        modelName: String
    ) async throws -> AIServiceResponse<String> {
        let body = ResponsesRequest(
            model: model,
            input: [.init(role: "user", content: content)],
            thinking: .init(type: thinking),
            stream: false,
            maxOutputTokens: maxOutputTokens
        )
        return try await request(
            body,
            apiKey: try resolvedAPIKey(for: model),
            modelName: modelName
        )
    }

    private static func request(
        _ body: ResponsesRequest,
        apiKey: String,
        modelName: String
    ) async throws -> AIServiceResponse<String> {
        try await AIServiceRequestRunner.run(modelName: modelName) {
            try await perform(
                body,
                apiKey: apiKey,
                modelName: modelName
            )
        }
    }

    private static func perform(
        _ body: ResponsesRequest,
        apiKey: String,
        modelName: String
    ) async throws -> AIServiceResponse<String> {
        if AIModelRouting.provider(
            for: body.model,
            deepSeekID: resolvedDeepSeekInferenceID()
        ) == .deepSeek {
            return AIServiceResponse(
                value: try await performDeepSeek(body, apiKey: apiKey, modelName: modelName),
                providerModelID: nil
            )
        }
        return try await performArk(body, apiKey: apiKey, modelName: modelName)
    }

}
