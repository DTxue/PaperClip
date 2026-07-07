import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("Test failed: \(message)\n", stderr)
        Foundation.exit(1)
    }
}

@main
struct AIModelRoutingTests {
    static func main() throws {
        try testDoubaoModelMigration()
        try testInferenceIDResolution()
        try testProviderAndAPIKeySelection()
        print("AIModelRoutingTests: 11 passed")
    }

    private static func testDoubaoModelMigration() throws {
        expect(
            AIModelRouting.migratedDoubaoInferenceID(nil, defaultID: "default") == "default",
            "missing doubao model should use default"
        )
        expect(
            AIModelRouting.migratedDoubaoInferenceID("  ", defaultID: "default") == "default",
            "blank doubao model should use default"
        )
        expect(
            AIModelRouting.migratedDoubaoInferenceID("doubao-vision-pro", defaultID: "default") == "default",
            "legacy doubao model should migrate to default endpoint"
        )
        expect(
            AIModelRouting.migratedDoubaoInferenceID(" ep-custom ", defaultID: "default") == "ep-custom",
            "custom endpoint should be trimmed and preserved"
        )
    }

    private static func testInferenceIDResolution() throws {
        let doubao = try AIModelRouting.inferenceID(
            for: .doubao,
            storedDoubaoID: " ep-custom ",
            defaultDoubaoID: "default-doubao",
            deepSeekID: "deepseek"
        )
        expect(doubao == "ep-custom", "doubao inference id should use migrated stored id")

        let deepSeek = try AIModelRouting.inferenceID(
            for: .deepSeek,
            storedDoubaoID: nil,
            defaultDoubaoID: "default-doubao",
            deepSeekID: " deepseek "
        )
        expect(deepSeek == "deepseek", "deepSeek inference id should be trimmed")

        do {
            _ = try AIModelRouting.inferenceID(
                for: .deepSeek,
                storedDoubaoID: nil,
                defaultDoubaoID: "default-doubao",
                deepSeekID: " "
            )
            expect(false, "blank deepSeek id should throw")
        } catch AIServiceError.missingDeepSeekEndpoint {
            expect(true, "blank deepSeek id throws expected error")
        }
    }

    private static func testProviderAndAPIKeySelection() throws {
        expect(
            AIModelRouting.provider(for: "deepseek", deepSeekID: "deepseek") == .deepSeek,
            "deepSeek id should route to deepSeek provider"
        )
        expect(
            AIModelRouting.provider(for: "ep-custom", deepSeekID: "deepseek") == .doubao,
            "non deepSeek id should route to doubao provider"
        )
        let apiKey = try AIModelRouting.apiKey(" key ", provider: .doubao)
        expect(apiKey == "key", "api key should be trimmed")

        do {
            _ = try AIModelRouting.apiKey(nil, provider: .deepSeek)
            expect(false, "missing deepSeek key should throw")
        } catch AIServiceError.missingDeepSeekAPIKey {
            expect(true, "missing deepSeek key throws expected error")
        }
    }
}
