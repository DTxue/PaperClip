import Foundation

extension AISettingsView {
    var canTestDoubaoConnection: Bool {
        !isTestingConnection
            && !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !doubaoEndpointID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canTestDeepSeekConnection: Bool {
        !isTestingConnection
            && !deepSeekAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func startDoubaoConnectionTest() {
        startConnectionTest {
            let result = try await AIService.recognize(image: AIConnectionTestSample.image())
            return AppAlert(
                title: "连接成功",
                message: "豆包已成功识别测试题目：\(result.recognizedQuestion)"
            )
        }
    }

    func startDeepSeekConnectionTest() {
        let recognition = AIConnectionTestSample.recognition

        startConnectionTest {
            let result = try await AIService.solve(
                question: recognition.recognizedQuestion,
                recognition: recognition,
                using: .deepSeek
            )
            return AppAlert(
                title: "连接成功",
                message: "DeepSeek 已成功解析测试题目：\(result.finalAnswer)"
            )
        }
    }

    func startConnectionTest(
        _ operation: @escaping () async throws -> AppAlert
    ) {
        cancelConnectionTest()
        saveSettings()
        isTestingConnection = true

        _ = connectionTestTaskSlot.start { taskID in
            do {
                let result = try await operation()
                try Task.checkCancellation()
                guard connectionTestTaskSlot.isCurrent(taskID) else { return }
                connectionTestAlert = result
            } catch is CancellationError {
                finishConnectionTest(taskID)
                return
            } catch {
                guard !Task.isCancelled,
                      connectionTestTaskSlot.isCurrent(taskID) else { return }
                connectionTestAlert = AppAlert(
                    title: "连接失败",
                    message: error.localizedDescription
                )
            }
            finishConnectionTest(taskID)
        }
    }

    func finishConnectionTest(_ taskID: UUID) {
        guard connectionTestTaskSlot.isCurrent(taskID) else { return }
        connectionTestTaskSlot.finish(taskID)
        isTestingConnection = false
    }

    func cancelConnectionTest() {
        connectionTestTaskSlot.cancel()
        isTestingConnection = false
    }
}
