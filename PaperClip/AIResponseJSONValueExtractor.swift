import Foundation

enum AIResponseJSONValueExtractor {
    static func extract(from content: String) -> String {
        extractJSONValue(from: stripCodeFence(from: content))
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

    private static func extractJSONValue(from content: String) -> String {
        let objectStart = content.firstIndex(of: "{")
        let arrayStart = content.firstIndex(of: "[")

        let start: String.Index?
        let end: String.Index?
        if let objectStart, let arrayStart {
            if objectStart < arrayStart {
                start = objectStart
                end = content.lastIndex(of: "}")
            } else {
                start = arrayStart
                end = content.lastIndex(of: "]")
            }
        } else if let objectStart {
            start = objectStart
            end = content.lastIndex(of: "}")
        } else if let arrayStart {
            start = arrayStart
            end = content.lastIndex(of: "]")
        } else {
            return content
        }

        guard let start, let end, start <= end else { return content }
        return String(content[start ... end])
    }
}
