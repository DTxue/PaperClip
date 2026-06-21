import Foundation
import UIKit

struct AIQuestionRecognition: Decodable, Sendable {
    let recognizedQuestion: String
    let subject: String
    let questionType: String
    let knowledgePoints: [String]
    let correctAnswer: String

    private enum CodingKeys: String, CodingKey {
        case recognizedQuestion, subject, questionType, knowledgePoints, correctAnswer
    }

    init(
        recognizedQuestion: String,
        subject: String,
        questionType: String,
        knowledgePoints: [String],
        correctAnswer: String = ""
    ) {
        self.recognizedQuestion = recognizedQuestion
        self.subject = subject
        self.questionType = questionType
        self.knowledgePoints = knowledgePoints
        self.correctAnswer = correctAnswer
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        recognizedQuestion = try container.decode(String.self, forKey: .recognizedQuestion)
        subject = try container.decode(String.self, forKey: .subject)
        questionType = try container.decode(String.self, forKey: .questionType)
        knowledgePoints = (try? container.decode([String].self, forKey: .knowledgePoints)) ?? []
        correctAnswer = (try? container.decode(String.self, forKey: .correctAnswer)) ?? ""
    }
}

struct AIQuestionSolution: Decodable, Sendable {
    struct SolutionStep: Decodable, Identifiable, Sendable {
        let number: Int
        let title: String
        let explanation: String

        var id: Int { number }

        // 部分模型将 number 返回为字符串，兼容两种格式
        private enum CodingKeys: String, CodingKey {
            case number, title, explanation
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            title = try c.decode(String.self, forKey: .title)
            explanation = try c.decode(String.self, forKey: .explanation)
            if let n = try? c.decode(Int.self, forKey: .number) {
                number = n
            } else if let s = try? c.decode(String.self, forKey: .number),
                      let n = Int(s) {
                number = n
            } else {
                number = 0
            }
        }
    }

    let solutionOverview: String
    let solutionSteps: [SolutionStep]
    let finalAnswer: String
    let commonMistakes: [String]

    private enum CodingKeys: String, CodingKey {
        case solutionOverview, solutionSteps, finalAnswer, commonMistakes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        solutionOverview = try c.decode(String.self, forKey: .solutionOverview)
        solutionSteps = try c.decode([SolutionStep].self, forKey: .solutionSteps)
        finalAnswer = try c.decode(String.self, forKey: .finalAnswer)
        commonMistakes = (try? c.decode([String].self, forKey: .commonMistakes)) ?? []
    }
}

struct AIQuestionAnalysis: Sendable {
    let recognizedQuestion: String
    let subject: String
    let questionType: String
    let knowledgePoints: [String]
    let solutionOverview: String
    let solutionSteps: [AIQuestionSolution.SolutionStep]
    let finalAnswer: String
    let commonMistakes: [String]

    init(
        recognition: AIQuestionRecognition,
        confirmedQuestion: String,
        solution: AIQuestionSolution
    ) {
        recognizedQuestion = confirmedQuestion
        subject = recognition.subject
        questionType = recognition.questionType
        knowledgePoints = recognition.knowledgePoints
        solutionOverview = solution.solutionOverview
        solutionSteps = solution.solutionSteps
        finalAnswer = solution.finalAnswer
        commonMistakes = solution.commonMistakes
    }
}

enum AIAnswerModel: String, CaseIterable, Identifiable, Sendable {
    case doubao
    case deepSeek

    var id: Self { self }

    var title: String {
        switch self {
        case .doubao: "豆包 Seed 2.0 Pro"
        case .deepSeek: "DeepSeek V4 Pro"
        }
    }

    var shortTitle: String {
        switch self {
        case .doubao: "豆包"
        case .deepSeek: "DeepSeek"
        }
    }

    var systemImage: String {
        switch self {
        case .doubao: "bolt.fill"
        case .deepSeek: "brain.head.profile"
        }
    }

    var summary: String {
        switch self {
        case .doubao: "速度快，适合常规题目"
        case .deepSeek: "深度推理，适合复杂数学与理科题"
        }
    }
}

private enum AIRecognitionPrompt {
    /// 动态构建，加入各科标准知识点词表，引导模型使用统一术语。
    static var instructions: String {
        """
        你是一名严谨的题目识别与答案生成助手。识别图片中的一道主要题目，并给出可用于批改的正确答案。

        规则：
        1. recognizedQuestion 必须忠实保留题号、题干、公式、图表文字和全部选项。
        2. 不得修正题目或补充图片中不存在的条件；但必须根据识别到的题目独立求出 correctAnswer。
        3. 图片不清晰或条件不足时，在 recognizedQuestion 中明确标注，并将 correctAnswer 设为空字符串，不得猜测。
        4. 数学公式使用 LaTeX：行内使用 $...$，独立公式使用 $$...$$。
        5. 所有内容使用简体中文。
        6. 只输出一个合法 JSON 对象，不要输出 Markdown 代码块或额外文字。
        7. JSON 必须严格使用以下结构：
        {
          "recognizedQuestion": "string",
          "subject": "string",
          "questionType": "string",
          "knowledgePoints": ["string"],
          "correctAnswer": "string"
        }
        8. questionType 必须且只能是以下值之一：选择题、填空题、判断题、计算题、阅读理解、简答题、证明题、作文题、其他。
        9. correctAnswer 只写最终答案，不写推导过程，并严格按题型输出：
           - 选择题：只输出选项字母；多选用英文逗号分隔，例如 A,C。
           - 判断题：只输出“正确”或“错误”。
           - 填空题：按空格顺序输出答案，多个空用中文分号分隔。
           - 计算题、证明题、简答题、阅读理解、作文题和其他：输出简洁、可核对的标准答案或参考答案。
        10. knowledgePoints 优先从下列标准词汇中选取（按识别到的学科选对应列），最多 5 个；若涉及词表以外的知识点可补充：
        \(KnowledgePointVocabulary.promptHint())
        """
    }
}

private enum AISolutionPrompt {
    static func instructions(
        question: String,
        recognition: AIQuestionRecognition
    ) -> String {
        """
        你是一位严谨的中学教师。请只根据学生已经确认的题目文本完成解析。

        学科：\(recognition.subject)
        题型：\(recognition.questionType)
        参考知识点：\(recognition.knowledgePoints.joined(separator: "、"))

        已确认题目：
        \(question)

        规则：
        1. 不得改写题目条件，不得引入题目之外的假设。
        2. 解题步骤必须可复核，关键推导说明依据。
        3. 数学公式使用 LaTeX：行内使用 $...$，独立公式使用 $$...$$。
        4. finalAnswer 只写最终结论；commonMistakes 给出 1 至 3 条具体易错点。
        5. 所有内容使用简体中文。
        6. 只输出一个合法 JSON 对象，不要输出 Markdown 代码块或额外文字。
        7. JSON 必须严格使用以下结构：
        {
          "solutionOverview": "string",
          "solutionSteps": [
            {
              "number": 1,
              "title": "string",
              "explanation": "string"
            }
          ],
          "finalAnswer": "string",
          "commonMistakes": ["string"]
        }
        """
    }
}

enum AIServiceError: LocalizedError {
    case missingAPIKey
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
        case .missingDeepSeekEndpoint:
            return "尚未配置 DeepSeek V4 Pro 推理接入点，请前往 AI 解析设置。"
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

enum AIService {
    static let defaultDoubaoInferenceID = "ep-20260620182757-zwqg9"
    static let defaultDeepSeekInferenceID = "ep-20260620195700-bp4j9"

    private static let requestTimeout: Duration = .seconds(90)
    private static let endpoint = URL(
        string: "https://ark.cn-beijing.volces.com/api/v3/responses"
    )!
    private static let maximumEncodedImageBytes = 8 * 1024 * 1024

    static var isDeepSeekConfigured: Bool {
        !resolvedDeepSeekInferenceID().isEmpty
    }

    static func recognize(image: UIImage) async throws -> AIQuestionRecognition {
        let apiKey = try resolvedAPIKey()
        let imageDataURL = try makeImageDataURL(from: image)
        let body = ResponsesRequest(
            model: try resolvedDoubaoInferenceID(),
            input: [
                .init(
                    role: "user",
                    content: [
                        .image(url: imageDataURL),
                        .text(AIRecognitionPrompt.instructions)
                    ]
                )
            ],
            thinking: .init(type: "disabled"),
            stream: false,
            maxOutputTokens: 4096
        )

        let content = try await request(
            body,
            apiKey: apiKey,
            modelName: "豆包识别"
        )
        return try decode(
            AIQuestionRecognition.self,
            from: content,
            modelName: "豆包识别"
        )
    }

    static func solve(
        question: String,
        recognition: AIQuestionRecognition,
        using model: AIAnswerModel
    ) async throws -> AIQuestionSolution {
        let confirmedQuestion = question.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !confirmedQuestion.isEmpty else {
            throw AIServiceError.invalidQuestion
        }

        let apiKey = try resolvedAPIKey()
        let body = ResponsesRequest(
            model: try inferenceID(for: model),
            input: [
                .init(
                    role: "user",
                    content: [
                        .text(
                            AISolutionPrompt.instructions(
                                question: confirmedQuestion,
                                recognition: recognition
                            )
                        )
                    ]
                )
            ],
            thinking: .init(type: model == .deepSeek ? "enabled" : "disabled"),
            stream: false,
            maxOutputTokens: model == .deepSeek ? 16384 : 8192
        )

        let content = try await request(
            body,
            apiKey: apiKey,
            modelName: model.title
        )
        return try decode(
            AIQuestionSolution.self,
            from: content,
            modelName: model.title
        )
    }

    static func migratedDoubaoInferenceID(_ value: String?) -> String {
        guard let value else { return defaultDoubaoInferenceID }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.lowercased()
        if normalized.isEmpty || normalized.hasPrefix("doubao-") {
            return defaultDoubaoInferenceID
        }
        return trimmed
    }

    private static func request(
        _ body: ResponsesRequest,
        apiKey: String,
        modelName: String
    ) async throws -> String {
        try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                do {
                    return try await perform(
                        body,
                        apiKey: apiKey,
                        modelName: modelName
                    )
                } catch let error as AIServiceError where shouldRetry(error) {
                    try await Task.sleep(for: .milliseconds(900))
                    return try await perform(
                        body,
                        apiKey: apiKey,
                        modelName: modelName
                    )
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

    private static func perform(
        _ body: ResponsesRequest,
        apiKey: String,
        modelName: String
    ) async throws -> String {
        var request = URLRequest(url: endpoint, timeoutInterval: 85)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

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
                message: serverErrorMessage(from: data)
            )
        }

        guard let responseBody = try? JSONDecoder().decode(
            ResponsesResponse.self,
            from: data
        ) else {
            throw AIServiceError.invalidServerResponse
        }
        guard let content = responseBody.outputText?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else {
            throw AIServiceError.emptyResponse(modelName)
        }
        return content
    }

    private static func resolvedAPIKey() throws -> String {
        guard let apiKey = KeychainService.load(for: .doubaoAPIKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !apiKey.isEmpty else {
            throw AIServiceError.missingAPIKey
        }
        return apiKey
    }

    private static func inferenceID(for model: AIAnswerModel) throws -> String {
        switch model {
        case .doubao:
            return try resolvedDoubaoInferenceID()
        case .deepSeek:
            let endpointID = resolvedDeepSeekInferenceID()
            guard !endpointID.isEmpty else {
                throw AIServiceError.missingDeepSeekEndpoint
            }
            return endpointID
        }
    }

    private static func resolvedDeepSeekInferenceID() -> String {
        let stored = KeychainService.load(for: .deepSeekModelID)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return stored.flatMap { $0.isEmpty ? nil : $0 }
            ?? defaultDeepSeekInferenceID
    }

    private static func resolvedDoubaoInferenceID() throws -> String {
        let stored = KeychainService.load(for: .doubaoModelID)
            ?? KeychainService.load(for: .doubaoVisionEndpoint)
            ?? defaultDoubaoInferenceID
        let migrated = migratedDoubaoInferenceID(stored)
        if migrated != stored.trimmingCharacters(in: .whitespacesAndNewlines) {
            KeychainService.save(migrated, for: .doubaoModelID)
        }
        guard !migrated.isEmpty else {
            throw AIServiceError.invalidModelID
        }
        return migrated
    }

    private static func decode<T: Decodable>(
        _ type: T.Type,
        from content: String,
        modelName: String
    ) throws -> T {
        let stripped = stripCodeFence(from: content)
        let json = fixUnescapedBackslashes(extractJSONObject(from: stripped))
        guard let data = json.data(using: .utf8) else {
            throw AIServiceError.malformedResponse(modelName, content)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let value = try? decoder.decode(type, from: data) else {
            throw AIServiceError.malformedResponse(modelName, String(content.prefix(400)))
        }
        return value
    }

    private static func shouldRetry(_ error: AIServiceError) -> Bool {
        if case .server(_, let statusCode, _) = error {
            return statusCode == 429 || statusCode >= 500
        }
        return false
    }

    private static func makeImageDataURL(from image: UIImage) throws -> String {
        let normalized = resized(image, maximumDimension: 2200)
        guard normalized.size.width > 0, normalized.size.height > 0,
              let data = normalized.jpegData(compressionQuality: 0.82) else {
            throw AIServiceError.invalidImage
        }
        guard data.count <= maximumEncodedImageBytes else {
            throw AIServiceError.imageTooLarge
        }
        return "data:image/jpeg;base64,\(data.base64EncodedString())"
    }

    private static func resized(_ image: UIImage, maximumDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image }
        let scale = min(maximumDimension / size.width, maximumDimension / size.height, 1)
        let targetSize = CGSize(
            width: (size.width * scale).rounded(),
            height: (size.height * scale).rounded()
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    private static func stripCodeFence(from content: String) -> String {
        guard content.hasPrefix("```") else { return content }
        var lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        if lines.first?.hasPrefix("```") == true {
            lines.removeFirst()
        }
        if lines.last?.trimmingCharacters(in: .whitespacesAndNewlines) == "```" {
            lines.removeLast()
        }
        return lines.joined(separator: "\n")
    }

    /// 修复 LLM 在 JSON 字符串中输出未转义反斜杠的问题（如 LaTeX \cdot、\frac 等）。
    /// 遍历 JSON，在字符串内部将单个 \ 全部转义为 \\，仅保留 \" 和 \\ 两种合法转义。
    private static func fixUnescapedBackslashes(_ json: String) -> String {
        var result = ""
        result.reserveCapacity(json.count + 64)
        var inString = false
        var idx = json.startIndex

        while idx < json.endIndex {
            let ch = json[idx]
            let next = json.index(after: idx)

            if inString {
                if ch == "\\" {
                    if next < json.endIndex {
                        let nc = json[next]
                        if nc == "\"" || nc == "\\" {
                            // \" 和 \\ 是合法 JSON 转义，原样保留并跳过下一字符
                            result.append(ch)
                            result.append(nc)
                            idx = json.index(after: next)
                            continue
                        } else {
                            // 其余单反斜杠（LaTeX 命令等）转义为 \\
                            result.append("\\")
                            result.append("\\")
                        }
                    } else {
                        result.append("\\")
                        result.append("\\")
                    }
                } else if ch == "\"" {
                    inString = false
                    result.append(ch)
                } else {
                    result.append(ch)
                }
            } else {
                if ch == "\"" { inString = true }
                result.append(ch)
            }

            idx = next
        }
        return result
    }

    private static func extractJSONObject(from content: String) -> String {
        guard let start = content.firstIndex(of: "{"),
              let end = content.lastIndex(of: "}"),
              start <= end else {
            return content
        }
        return String(content[start ... end])
    }

    private static func serverErrorMessage(from data: Data) -> String {
        if let response = try? JSONDecoder().decode(ArkErrorResponse.self, from: data) {
            return String(response.error.message.prefix(500))
        }
        if let body = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !body.isEmpty {
            return String(body.prefix(500))
        }
        return "请检查 API Key、推理接入点和火山方舟服务状态。"
    }
}

private struct ResponsesRequest: Encodable, Sendable {
    struct Input: Encodable, Sendable {
        let role: String
        let content: [Content]
    }

    enum Content: Encodable, Sendable {
        case image(url: String)
        case text(String)

        private enum CodingKeys: String, CodingKey {
            case type
            case imageURL = "image_url"
            case text
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .image(let url):
                try container.encode("input_image", forKey: .type)
                try container.encode(url, forKey: .imageURL)
            case .text(let text):
                try container.encode("input_text", forKey: .type)
                try container.encode(text, forKey: .text)
            }
        }
    }

    struct Thinking: Encodable, Sendable {
        let type: String
    }

    private enum CodingKeys: String, CodingKey {
        case model, input, thinking, stream
        case maxOutputTokens = "max_output_tokens"
    }

    let model: String
    let input: [Input]
    let thinking: Thinking
    let stream: Bool
    let maxOutputTokens: Int

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(model, forKey: .model)
        try c.encode(input, forKey: .input)
        try c.encode(thinking, forKey: .thinking)
        try c.encode(stream, forKey: .stream)
        try c.encode(maxOutputTokens, forKey: .maxOutputTokens)
    }
}

private struct ResponsesResponse: Decodable {
    struct OutputItem: Decodable {
        struct Content: Decodable {
            let type: String?
            let text: String?
        }

        let type: String?
        let content: [Content]?
    }

    let output: [OutputItem]
    let outputTextValue: String?

    enum CodingKeys: String, CodingKey {
        case output
        case outputTextValue = "output_text"
    }

    var outputText: String? {
        if let outputTextValue, !outputTextValue.isEmpty {
            return outputTextValue
        }
        let contentItems = output
            .filter { $0.type == nil || $0.type == "message" }
            .compactMap(\.content)
            .flatMap { $0 }
        return contentItems
            .first { $0.type == nil || $0.type == "output_text" || $0.type == "text" }?
            .text
    }
}

private struct ArkErrorResponse: Decodable {
    struct Detail: Decodable {
        let message: String
    }

    let error: Detail
}
