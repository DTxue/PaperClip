import Foundation

enum AIResponseJSONSanitizer {
    static func sanitizedJSONValue(from content: String) -> String {
        fixUnescapedBackslashes(
            AIResponseJSONValueExtractor.extract(from: content)
        )
    }

    private static func fixUnescapedBackslashes(_ json: String) -> String {
        var result = ""
        result.reserveCapacity(json.count + 64)
        var inString = false
        var index = json.startIndex

        while index < json.endIndex {
            let character = json[index]
            let next = json.index(after: index)

            if inString {
                if character == "\\" {
                    if next < json.endIndex,
                       isValidJSONEscape(in: json, escapeIndex: index) {
                        result.append(character)
                        result.append(json[next])
                        index = json.index(after: next)
                        continue
                    } else {
                        result.append("\\")
                        result.append("\\")
                    }
                } else if character == "\"" {
                    inString = false
                    result.append(character)
                } else {
                    result.append(character)
                }
            } else {
                if character == "\"" {
                    inString = true
                }
                result.append(character)
            }

            index = next
        }
        return result
    }

    private static func isValidJSONEscape(in json: String, escapeIndex: String.Index) -> Bool {
        let escapedIndex = json.index(after: escapeIndex)
        guard escapedIndex < json.endIndex else { return false }

        switch json[escapedIndex] {
        case "\"", "\\", "/", "b", "f", "n", "r", "t":
            return true
        case "u":
            var index = json.index(after: escapedIndex)
            for _ in 0 ..< 4 {
                guard index < json.endIndex,
                      json[index].isHexDigit else {
                    return false
                }
                index = json.index(after: index)
            }
            return true
        default:
            return false
        }
    }
}
