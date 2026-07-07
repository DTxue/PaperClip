import Foundation

extension AIService {
    static func send(
        _ request: URLRequest,
        modelName: String,
        errorMessage: (Data) -> String
    ) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw AIServiceError.network(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidServerResponse
        }
        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw AIServiceError.server(
                model: modelName,
                statusCode: httpResponse.statusCode,
                message: errorMessage(data)
            )
        }
        return data
    }

    static func responseSnippet(from data: Data, fallback: String, limit: Int = 400) -> String {
        String(
            (String(data: data, encoding: .utf8) ?? fallback)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(limit)
        )
    }
}
