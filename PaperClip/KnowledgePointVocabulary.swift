import Foundation

/// 各学科初中阶段标准知识点词表。
/// 供两处使用：
/// 1. AI 识别提示词 —— 引导模型使用统一术语
/// 2. 错题卡编辑器 —— 快速添加标签的候选词
enum KnowledgePointVocabulary {

    /// 返回指定学科的知识点列表（按教学顺序排列）。
    static func points(for subject: String) -> [String] {
        uniqueVocabulary[subject] ?? []
    }

    /// 生成供 AI 识别提示词使用的精简词表文本。
    static func promptHint() -> String {
        promptSubjects.compactMap { subject -> String? in
            let pts = points(for: subject.rawValue)
            guard !pts.isEmpty else { return nil }
            // 每科取前 30 个最核心词汇，避免 prompt 过长
            let sample = pts.prefix(30).joined(separator: "、")
            return "\(subject.rawValue)：\(sample)"
        }.joined(separator: "\n")
    }

    private static let promptSubjects: [Subject] = [
        .math, .physics, .chemistry,
        .chinese, .english, .biology, .geography, .history, .politics
    ]

    private static let uniqueVocabulary: [String: [String]] = vocabulary.mapValues { points in
        var seen = Set<String>()
        seen.reserveCapacity(points.count)
        return points.filter { seen.insert($0).inserted }
    }

    private static let vocabulary = KnowledgePointVocabularySeed.vocabulary
}
