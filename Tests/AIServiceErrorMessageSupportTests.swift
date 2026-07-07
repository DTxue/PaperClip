import Foundation

@main
struct AIServiceErrorMessageSupportTests {
    static func main() {
        testArkStructuredMessage()
        testDeepSeekStructuredMessage()
        testPlainTextFallback()
        testDefaultFallback()
        testProviderResponseDecodeWrapsMalformedData()
        testRequestRetryPolicy()
        print("AIServiceErrorMessageSupportTests: 6 passed")
    }

    private static func testArkStructuredMessage() {
        let data = #"{"error":{"message":"模型不存在"}}"#.data(using: .utf8)!
        let message = AIServiceErrorMessageSupport.message(
            from: data,
            defaultMessage: "default",
            decode: ArkErrorResponse.self
        ) { $0.error.message }

        expect(message == "模型不存在", "Ark structured error should be preferred")
    }

    private static func testDeepSeekStructuredMessage() {
        let data = #"{"error":{"message":"余额不足"}}"#.data(using: .utf8)!
        let message = AIServiceErrorMessageSupport.message(
            from: data,
            defaultMessage: "default",
            decode: DeepSeekErrorResponse.self
        ) { $0.error?.message }

        expect(message == "余额不足", "DeepSeek structured error should be preferred")
    }

    private static func testPlainTextFallback() {
        let data = "  gateway timeout  ".data(using: .utf8)!
        let message = AIServiceErrorMessageSupport.message(
            from: data,
            defaultMessage: "default",
            decode: DeepSeekErrorResponse.self
        ) { $0.error?.message }

        expect(message == "gateway timeout", "plain text body should be used when JSON decode fails")
    }

    private static func testDefaultFallback() {
        let data = Data()
        let message = AIServiceErrorMessageSupport.message(
            from: data,
            defaultMessage: "default",
            decode: DeepSeekErrorResponse.self
        ) { $0.error?.message }

        expect(message == "default", "default message should be used for empty bodies")
    }

    private static func testProviderResponseDecodeWrapsMalformedData() {
        struct Response: Decodable {
            let value: String
        }

        let data = "not-json".data(using: .utf8)!
        do {
            _ = try AIServiceErrorMessageSupport.decodeProviderResponse(
                Response.self,
                from: data,
                modelName: "Provider"
            )
            fatalError("Expected malformedResponse")
        } catch AIServiceError.malformedResponse(let model, let raw) {
            expect(model == "Provider", "model name should be preserved")
            expect(raw == "not-json", "raw response snippet should be preserved")
        } catch {
            fatalError("Unexpected error: \(error)")
        }
    }

    private static func testRequestRetryPolicy() {
        expect(AIServiceRequestRunner.shouldRetry(
            .server(model: "test", statusCode: 429, message: "rate limited")
        ), "rate limits should be retried")
        expect(AIServiceRequestRunner.shouldRetry(
            .server(model: "test", statusCode: 500, message: "server error")
        ), "server errors should be retried")
        expect(!AIServiceRequestRunner.shouldRetry(
            .server(model: "test", statusCode: 400, message: "bad request")
        ), "client errors should not be retried")
        expect(!AIServiceRequestRunner.shouldRetry(.network("offline")), "network errors should not be retried")
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError(message, file: file, line: line)
        }
    }
}
