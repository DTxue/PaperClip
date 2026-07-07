import Foundation

struct ArkErrorResponse: Decodable {
    struct Detail: Decodable {
        let message: String
    }

    let error: Detail
}

struct DeepSeekErrorResponse: Decodable {
    struct ErrorDetail: Decodable {
        let message: String
    }

    let error: ErrorDetail?
}
