import Foundation

struct AIMistakeRecognitionResult: Decodable, Sendable {
    let questionText: String
    let subject: String?
    let grade: String?
    let knowledgePoints: [String]?
}

enum MistakeRecognitionPrompt {
    static let instruction = """
    请将图片中的错题题干完整转写为文字，并识别它的学科、适用年级和知识点。只做识别和分类，不要解题、不要给答案、不要补充解析。

    规则：
    1. 按图片顺序合并多张图片中的题目内容。
    2. 保留题号、选项、公式、单位、标点和必要的换行。
    3. 数学和科学公式使用 LaTeX 表达：行内公式必须放在 $...$ 中，独立公式必须放在 $$...$$ 中。
    4. 无法确定的字符用 [?] 标记，不要自行猜测或纠正题目。
    5. 学科只能从以下值中选择：语文、数学、英语、物理、化学、生物、历史、地理、道德与法治、音乐、美术、体育、信息技术；无法判断时返回 null。
    6. 年级只能从以下值中选择：七年级、八年级、九年级；无法判断时返回 null。
    7. 知识点返回 1 至 3 个简短、具体、可用于整理和检索的名称；无法判断时返回空数组。不要把学科名称本身当作知识点。
    8. 只输出合法 JSON，不要输出 Markdown 或额外文字。

    JSON 结构：
    {
      "questionText": "识别出的完整题目文字",
      "subject": "数学",
      "grade": "七年级",
      "knowledgePoints": ["有理数加法", "基础运算"]
    }
    """
}

enum MistakeRecognitionAutofill {
    static func shouldApplyRecognizedValue(
        current: String,
        requestStart: String
    ) -> Bool {
        current == requestStart
    }

    static func mergedKnowledgePoints(
        existing: String,
        recognized: [String]
    ) -> String {
        var result: [String] = []
        var seen: Set<String> = []

        for value in components(in: existing) + recognized {
            let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty, seen.insert(normalized).inserted else { continue }
            result.append(normalized)
        }
        return result.joined(separator: ",")
    }

    private static func components(in value: String) -> [String] {
        value
            .replacingOccurrences(of: "，", with: ",")
            .replacingOccurrences(of: "、", with: ",")
            .split(separator: ",")
            .map(String.init)
    }
}
