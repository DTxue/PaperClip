enum KnowledgeAIAnalysisOutputSchema {
    static let text = """
    只输出合法 JSON 对象，不含 Markdown 代码块，字段值为字符串（不要输出 JSON 数组）：
    {
      "subject": "学科名",
      "essence": "...",
      "formula": "...",
      "solutionPath": "①...\\n②...\\n③...",
      "trap": "①...（例如：……）\\n②...（例如：……）",
      "related": "①...，常结合……考查\\n②...，常结合……考查",
      "memoryAnchor": "..."
    }
    """
}
