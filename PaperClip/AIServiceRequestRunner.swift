import Foundation

enum AIServiceRequestRunner {
    private static let requestTimeout: Duration = .seconds(240)

    static func run<Result: Sendable>(
        modelName: String,
        operation: @escaping @Sendable () async throws -> Result
    ) async throws -> Result {
        try await withThrowingTaskGroup(of: Result.self) { group in
            group.addTask {
                do {
                    return try await operation()
                } catch let error as AIServiceError where shouldRetry(error) {
                    try await Task.sleep(for: .milliseconds(900))
                    return try await operation()
                }
            }
            group.addTask {
                try await Task.sleep(for: requestTimeout)
                throw AIServiceError.requestTimedOut(modelName)
            }

            defer { group.cancelAll() }
            guard let result = try await group.next() else {
                throw AIServiceError.invalidServerResponse
            }
            return result
        }
    }

    static func shouldRetry(_ error: AIServiceError) -> Bool {
        if case .server(_, let statusCode, _) = error {
            return statusCode == 429 || statusCode >= 500
        }
        return false
    }
}
