import Foundation

enum MistakeTagParser {
    private static let separators = CharacterSet(charactersIn: ",，\n")

    static func parse(_ raw: String) -> [String] {
        normalize(raw.components(separatedBy: separators))
    }

    static func normalize(_ tags: [String]) -> [String] {
        var normalized: [String] = []
        var seen = Set<String>()
        for rawTag in tags {
            let tag = rawTag.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !tag.isEmpty, seen.insert(tag).inserted else { continue }
            normalized.append(tag)
        }
        return normalized
    }

    static func serialize(_ tags: [String]) -> String {
        normalize(tags).joined(separator: ",")
    }

    static func appending(_ rawNewTags: String, to existingTags: [String]) -> [String] {
        appending(parse(rawNewTags), to: existingTags)
    }

    static func appending(_ newTags: [String], to existingTags: [String]) -> [String] {
        normalize(existingTags + newTags)
    }
}

enum MistakeTagSummary {
    static func add(_ tags: [String], to counts: inout [String: Int]) {
        for tag in tags {
            counts[tag, default: 0] += 1
        }
    }

    static func topTags(from counts: [String: Int], limit: Int) -> [(tag: String, count: Int)] {
        counts
            .sorted { lhs, rhs in
                if lhs.value != rhs.value { return lhs.value > rhs.value }
                return lhs.key < rhs.key
            }
            .prefix(limit)
            .map { (tag: $0.key, count: $0.value) }
    }
}

enum MistakeTagDisplay {
    static func preview(_ tags: [String], limit: Int) -> String {
        tags.prefix(limit).joined(separator: " · ")
    }

    static func accessibilityList(_ tags: [String]) -> String {
        tags.joined(separator: "、")
    }
}
