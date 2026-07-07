import Foundation

extension String {
    func components(separatedBy expression: NSRegularExpression) -> [String] {
        let range = NSRange(startIndex..<endIndex, in: self)
        return components(separatedBy: expression, range: range)
    }

    func components(separatedByRegex pattern: String) -> [String] {
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return [self]
        }
        let range = NSRange(startIndex..<endIndex, in: self)
        return components(separatedBy: expression, range: range)
    }

    private func components(
        separatedBy expression: NSRegularExpression,
        range: NSRange
    ) -> [String] {
        var result: [String] = []
        var lastLocation = 0

        for match in expression.matches(in: self, range: range) {
            let matchRange = match.range
            let segmentRange = NSRange(location: lastLocation, length: matchRange.location - lastLocation)
            if let range = Range(segmentRange, in: self) {
                result.append(String(self[range]))
            }
            lastLocation = matchRange.location + matchRange.length
        }

        let tailRange = NSRange(location: lastLocation, length: range.length - lastLocation)
        if let range = Range(tailRange, in: self) {
            result.append(String(self[range]))
        }
        return result
    }
}
