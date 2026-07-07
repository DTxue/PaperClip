enum VocabularyAnsweringActionTitle {
    static func title(isExam: Bool, isLastInBatch: Bool, isLastBatch: Bool) -> String {
        guard isLastInBatch else { return "下一题" }
        guard isExam else { return "提交答卷" }
        return isLastBatch ? "提交全卷" : "提交并继续"
    }
}
