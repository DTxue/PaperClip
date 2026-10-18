import Foundation

enum VocabularyAIPrompts {
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

    static func englishDefinitions(cards: [VocabularyEnglishDefinitionInput]) -> String {
        let items = cards.enumerated().map { index, card in
            """
            \(index + 1). term: \(card.term)
               Chinese meaning: \(card.definition)
               partOfSpeech: \(card.partOfSpeech.isEmpty ? "N/A" : card.partOfSpeech)
               example: \(card.example.isEmpty ? "N/A" : card.example)
            """
        }.joined(separator: "\n")

        return """
        You are an English vocabulary assistant for Chinese middle school students.
        Write one short English definition for each vocabulary card.

        Requirements:
        1. Use very simple and common English words for Grade 7-9 learners.
        2. Explain the meaning shown by the Chinese meaning. Do not explain a different meaning.
        3. Use 5-14 English words when possible.
        4. Use one simple phrase or one simple sentence. Avoid rare words, idioms, and complex clauses.
        5. Do not use Chinese.
        6. For a single English word, do not use that exact word to define itself.
        7. Return every item with the same 1-based index. Return only valid JSON, no Markdown code block:
        {"items":[{"index":1,"englishDefinition":"..."},{"index":2,"englishDefinition":"..."}]}

        Vocabulary cards:
        \(items)
        """
    }

    static func handwritingRecognitionQuestionText(
        index: Int,
        hasAnswer: Bool
    ) -> String {
        var text = "第\(index + 1)题"
        if !hasAnswer { text += "\n（未作答）" }
        return text
    }

    static func handwritingRecognitionInstruction(count: Int, isChinese: Bool) -> String {
        let languageInstruction: String
        if isChinese {
            languageInstruction = """
            请识别图片中的学生手写中文，并逐字如实转写。
            严禁参考常用语、成语、诗词名句、课文、名言、答案或上下文纠错、补全、替换或润色。
            即使内容看起来明显有误，也只能照笔迹记录；看不清时输出替代字符“�”，不得猜测。
            """
        } else {
            languageInstruction = "请识别图片中的学生手写英文。"
        }
        return """
        第一原则：只识别以上 \(count) 题图片中的学生笔迹，并如实转写图片中实际可见的内容。
        \(languageInstruction)
        不要批改、纠正、补全、改写或猜测用户原本想写的答案，也不要利用语言知识修正笔迹。
        必须保留识别到的字符、顺序和标点；不得擅自添加或删除字符。
        已作答题的 recognizedText 必须忠实记录图片中的文字；整题无法可靠识别时填空字符串，不要猜测。未作答也填空字符串。
        isCorrect 固定返回 false，comment 固定返回空字符串；正确性将在本地与参考答案比较。
        必须返回恰好 \(count) 个 items，index 必须从 1 到 \(count) 连续完整。
        仅输出合法 JSON，不含 Markdown 代码块：
        {"items":[{"index":1,"isCorrect":false,"recognizedText":"student handwriting","comment":""}]}
        """
    }

    static func chineseCharacterRecognitionInstruction() -> String {
        """
        本请求只识别当前图片中的一个方格和一个字符。
        只根据当前字形识别一个汉字或标点，禁止结合其他格、词语、整句、答案或上下文判断。
        不得按常用语、成语、诗词、课文或名言纠错、补全、替换或润色。即使结果不通顺，也必须照笔迹识别。
        recognizedText 必须恰好是一个字符；无法可靠辨认时填“�”。isCorrect 固定为 false，comment 固定为空字符串。
        仅输出一个 item，index 为 1，且只输出合法 JSON：
        {"items":[{"index":1,"isCorrect":false,"recognizedText":"","comment":""}]}
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
