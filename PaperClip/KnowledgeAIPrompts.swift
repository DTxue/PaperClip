import Foundation

enum KnowledgeAIPrompts {
    static func extract(text: String, source: String) -> String {
        let sourceDesc = source == "learned" ? "今天学到的内容" : "今天没搞懂的地方"
        return """
        你是一位细心的学习助手，帮助学生整理日记内容。

        学生写的\(sourceDesc)：
        \(text)

        请按以下规则处理，不做其他修改：
        1. 纠正明显的错别字
        2. 补全缺失的标点符号
        3. 将多个混写在一起的内容拆分成独立条目
        4. 不要改写、润色、总结或添加学生没有写到的内容
        5. 每条尽量保留学生的原始表达

        输出合法 JSON 数组，每个元素是对象：
        - "text"：整理后的条目内容
        - "change"：如有改动，用一句话描述具体改动（如「"牛頓" → "牛顿"（错别字）」或「补全了句末句号」或「从混合内容中拆分」）；无改动则省略此字段或设为 null

        只输出 JSON 数组，不含 Markdown 代码块：
        [{"text":"条目1","change":"改动说明"},{"text":"条目2"}]
        """
    }

    static func analyze(_ summary: String) -> String {
        """
        你是一位经验丰富的中学备考教师。请识别知识点所属学科，按该学科考试特性给出精简解析。

        知识点：\(summary)

        字数要求：每个字段不超过60字，全部字段合计不超过350字。数学公式用 LaTeX（行内$...$，独立$$...$$）。

        \(KnowledgeAIAnalysisSubjectStrategies.text)

        \(KnowledgeAIAnalysisOutputSchema.text)
        """
    }
}
