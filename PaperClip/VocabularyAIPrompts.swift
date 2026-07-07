import Foundation

enum VocabularyAIPrompts {
    static func article(cards: [VocabularyArticleCardInput]) -> String {
        let items = cards.enumerated().map { index, card in
            """
            \(index + 1). term: \(card.term)
               definition: \(card.definition)
               phonetic: \(card.phonetic.isEmpty ? "N/A" : card.phonetic)
               partOfSpeech: \(card.partOfSpeech.isEmpty ? "N/A" : card.partOfSpeech)
               example: \(card.example.isEmpty ? "N/A" : card.example)
               tags: \(card.tagsText.isEmpty ? "N/A" : card.tagsText)
               note: \(card.note.isEmpty ? "N/A" : card.note)
               alternativeAnswers: \(card.alternativeAnswersText.isEmpty ? "N/A" : card.alternativeAnswersText)
            """
        }.joined(separator: "\n")

        return """
        You are an English vocabulary learning assistant.
        Create one coherent English article from all vocabulary content below.

        Requirements:
        1. Use clear, natural, easy English suitable for a learner to memorize.
        2. Cover every vocabulary item. Include each English term or phrase exactly as written at least once when possible.
        3. Integrate definitions, examples, notes, and alternative answers naturally. Do not write a list.
        4. Keep the story/article coherent, concrete, and easy to recite aloud.
        5. Use complete sentences and avoid rare grammar.
        6. Return only valid JSON, no Markdown code block:
        {"title":"...","article":"...","coveredTerms":["..."]}

        Vocabulary content:
        \(items)
        """
    }

    static func splitCard(term: String, definition: String) -> String {
        """
        你是英语词汇整理助手。请将以下词条拆分成若干独立词条。

        英文词条：\(term)
        中文释义：\(definition)

        规则：
        1. 若词条用"/"或","分隔了多个表达（如 "hang / put the picture"），逐一拆分为独立词条。
        2. 若含多个独立用法或语义，按语义边界拆分。
        3. 每条拆分结果须完整、独立、可单独记忆；中文释义随之对应拆分。
        4. 若原词条无需拆分，返回仅含原词条的单元素数组。
        5. 仅输出合法 JSON，不含 Markdown 代码块：
        {"cards":[{"term":"...","definition":"..."}]}
        """
    }

    static func distractors(
        term: String,
        definition: String,
        partOfSpeech: String,
        example: String,
        config: DistractorConfig
    ) -> String {
        let posHint = partOfSpeech.isEmpty ? "不限" : partOfSpeech
        let exampleHint = example.isEmpty ? "无" : example
        return """
        你是英语词汇学习题目生成助手，负责生成「词块拼句」题型所需数据。

        英文内容：\(term)
        中文含义：\(definition)
        词性：\(posHint)
        例句：\(exampleHint)

        规则：
        1. correctTiles：将英文内容拆成 1–6 个词块。单词 = 1 块；短语 = 2–3 块；句子 = 3–6 块。
        2. distractorTiles：\(distractorInstruction(for: config))不得与任何正确词块完全相同。
        3. 仅输出合法 JSON，不含 Markdown 代码块：
        {"correctTiles":["..."],"distractorTiles":["..."]}
        """
    }

    static func gradingQuestionText(
        index: Int,
        term: String,
        definition: String,
        hasAnswer: Bool
    ) -> String {
        var text = "第\(index + 1)题\n中文含义：\(definition)\n正确英文：\(term)"
        if !hasAnswer { text += "\n（未作答）" }
        return text
    }

    static func gradingInstruction(count: Int) -> String {
        """
        请批改以上 \(count) 题手写答案。
        判断标准：手写内容与正确英文拼写一致（忽略大小写，不允许拼写错误或遗漏字母）。未作答的题直接判为错误。
        recognizedText 字段写 AI 识别出的学生手写英文；正确题可为空，错误题必须填写识别出的错误内容，未作答填空字符串。
        comment 字段只写结论，不超过15字，不要写推理过程。
        仅输出合法 JSON，不含 Markdown 代码块：
        {"items":[{"index":1,"isCorrect":true,"recognizedText":"","comment":"正确"},{"index":2,"isCorrect":false,"recognizedText":"XXX","comment":"写作 XXX"}]}
        """
    }

    private static func distractorInstruction(for config: DistractorConfig) -> String {
        let breakdown = config.countBreakdown
        guard !breakdown.isEmpty else {
            return "生成 \(config.totalCount) 个干扰单词（每项必须是单个英文单词，禁止短语或多词组合）。"
        }
        let lines = breakdown.map { "   - \($0.type)：\($0.count) 个" }.joined(separator: "\n")
        return "生成恰好 \(config.totalCount) 个干扰单词（每项必须是单个英文单词，禁止短语或多词组合），按以下类型分配：\n\(lines)"
    }
}
