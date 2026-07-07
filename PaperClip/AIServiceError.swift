import Foundation

enum AIServiceError: LocalizedError {
    case missingAPIKey
    case missingDeepSeekAPIKey
    case missingDeepSeekEndpoint
    case invalidModelID
    case invalidQuestion
    case invalidImage
    case imageTooLarge
    case invalidServerResponse
    case server(model: String, statusCode: Int, message: String)
    case requestTimedOut(String)
    case emptyResponse(String)
    case malformedResponse(String, String)
    case network(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "尚未配置火山方舟 API Key，请前往“设置 → AI 解析设置”。"
        case .missingDeepSeekAPIKey:
            return "尚未配置 DeepSeek API Key，请前往“设置 → AI 解析设置”。"
        case .missingDeepSeekEndpoint:
            return "尚未配置 DeepSeek 推理模型，请前往 AI 解析设置。"
        case .invalidModelID:
            return "推理接入点 ID 为空，请前往 AI 解析设置检查配置。"
        case .invalidQuestion:
            return "确认后的题目内容为空，请先检查题目文本。"
        case .invalidImage:
            return "题目图片无法编码，请重新框选后再试。"
        case .imageTooLarge:
            return "题目图片数据过大，请缩小框选范围后再试。"
        case .invalidServerResponse:
            return "火山方舟返回了无法识别的响应。"
        case .server(let model, let statusCode, let message):
            return "\(model) 请求失败（\(statusCode)）：\(message)"
        case .requestTimedOut(let model):
            return "\(model) 请求超过 90 秒，已自动停止，请重试。"
        case .emptyResponse(let model):
            return "\(model) 没有返回内容，请重试。"
        case .malformedResponse(let model, let raw):
            return "\(model) 返回的数据格式不完整。\n原始内容：\(raw)"
        case .network(let message):
            return "网络请求失败：\(message)"
        }
    }
}
