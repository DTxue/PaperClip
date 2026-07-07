import Foundation

struct KnowledgeAnalysisDecodable: Decodable {
    let subject: String
    let essence: String
    let formula: String
    let solutionPath: String
    let trap: String
    let related: String
    let memoryAnchor: String

    private static func normalize(_ s: String) -> String {
        s.replacingOccurrences(of: "\\n", with: "\n")
    }

    private static func flexString(
        from container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> String {
        if let s = try? container.decode(String.self, forKey: key) { return normalize(s) }
        if let arr = try? container.decode([String].self, forKey: key) { return arr.joined(separator: "\n") }
        return ""
    }

    private enum CodingKeys: String, CodingKey {
        case subject, essence, formula, solutionPath, trap, related, memoryAnchor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        subject = (try? container.decode(String.self, forKey: .subject)) ?? ""
        essence = Self.normalize((try? container.decode(String.self, forKey: .essence)) ?? "")
        formula = Self.normalize((try? container.decode(String.self, forKey: .formula)) ?? "")
        solutionPath = Self.flexString(from: container, key: .solutionPath)
        trap = Self.flexString(from: container, key: .trap)
        related = Self.flexString(from: container, key: .related)
        memoryAnchor = Self.normalize((try? container.decode(String.self, forKey: .memoryAnchor)) ?? "")
    }

    func toAnalysis() -> KnowledgeAnalysis {
        KnowledgeAnalysis(
            subject: subject,
            essence: essence,
            formula: formula,
            solutionPath: solutionPath,
            trap: trap,
            related: related,
            memoryAnchor: memoryAnchor
        )
    }
}
