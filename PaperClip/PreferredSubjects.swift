import Foundation

enum PreferredSubjects {
    private static let fallbackSubject = "数学"

    static func parse(_ raw: String) -> [String] {
        var subjects: [String] = []
        for item in raw.split(separator: ",") {
            let subject = item.trimmingCharacters(in: .whitespacesAndNewlines)
            if !subject.isEmpty {
                subjects.append(subject)
            }
        }
        return subjects
    }

    static func parseSet(_ raw: String) -> Set<String> {
        var subjects: Set<String> = []
        for item in raw.split(separator: ",") {
            let subject = item.trimmingCharacters(in: .whitespacesAndNewlines)
            if !subject.isEmpty {
                subjects.insert(subject)
            }
        }
        return subjects
    }

    static func serialize(_ subjects: Set<String>) -> String {
        Subject.allCases
            .map(\.rawValue)
            .filter(subjects.contains)
            .joined(separator: ",")
    }

    /// 默认导入学科：第一个常用学科，否则数学。
    static func defaultSubject(_ raw: String) -> String {
        parse(raw).first ?? fallbackSubject
    }
}
