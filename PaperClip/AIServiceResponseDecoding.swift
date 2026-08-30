import Foundation

extension AIService {
    static func requestDecoded<T: Decodable>(
        _ type: T.Type,
        _ prompt: String,
        configuration: AIRequestConfiguration
    ) async throws -> T {
        try await requestDecoded(
            type,
            prompt,
            model: try inferenceID(for: configuration.model),
            thinking: configuration.thinking,
            maxOutputTokens: configuration.maxOutputTokens,
            modelName: configuration.modelName
        )
    }

    static func requestDecoded<T: Decodable>(
        _ type: T.Type,
        _ prompt: String,
        model: String,
        thinking: String,
        maxOutputTokens: Int,
        modelName: String
    ) async throws -> T {
        let content = try await requestText(
            prompt,
            model: model,
            thinking: thinking,
            maxOutputTokens: maxOutputTokens,
            modelName: modelName
        )
        return try decode(type, from: content, modelName: modelName)
    }

    static func requestDecoded<T: Decodable>(
        _ type: T.Type,
        content: [ResponsesRequest.Content],
        configuration: AIRequestConfiguration
    ) async throws -> T {
        try await requestDecoded(
            type,
            content: content,
            model: try inferenceID(for: configuration.model),
            thinking: configuration.thinking,
            maxOutputTokens: configuration.maxOutputTokens,
            modelName: configuration.modelName
        )
    }

    static func requestDecoded<T: Decodable>(
        _ type: T.Type,
        content: [ResponsesRequest.Content],
        model: String,
        thinking: String,
        maxOutputTokens: Int,
        modelName: String
    ) async throws -> T {
        let response = try await requestContent(
            content,
            model: model,
            thinking: thinking,
            maxOutputTokens: maxOutputTokens,
            modelName: modelName
        )
        return try decode(type, from: response, modelName: modelName)
    }

    static func requestDecodedResponse<T: Decodable & Sendable>(
        _ type: T.Type,
        content: [ResponsesRequest.Content],
        configuration: AIRequestConfiguration
    ) async throws -> AIServiceResponse<T> {
        let response = try await requestContentResponse(
            content,
            configuration: configuration
        )
        return AIServiceResponse(
            value: try decode(
                type,
                from: response.value,
                modelName: configuration.modelName
            ),
            providerModelID: response.providerModelID
        )
    }

    static func sanitizedJSONValue(from content: String) -> String {
        AIResponseDecodingSupport.sanitizedJSONValue(from: content)
    }

    static func decode<T: Decodable>(
        _ type: T.Type,
        from content: String,
        modelName: String
    ) throws -> T {
        do {
            return try AIResponseDecodingSupport.decodedJSONValue(type, from: content)
        } catch AIResponseDecodingSupport.DecodingFailure.invalidUTF8 {
            throw AIServiceError.malformedResponse(modelName, content)
        } catch {
            throw AIServiceError.malformedResponse(modelName, String(content.prefix(400)))
        }
    }

}
