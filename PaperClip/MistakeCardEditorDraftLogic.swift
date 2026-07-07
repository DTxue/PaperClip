import Foundation

enum MistakeCardEditorDraftLogic {
    static func printHeight(printWidthMM: Double, aspectRatio: Double) -> Double {
        printWidthMM / max(aspectRatio, 0.01)
    }

    static func subjectsForPicker(preferredSubjectsRaw: String, currentSubject: String) -> [Subject] {
        let preferred = PreferredSubjects.parseSet(preferredSubjectsRaw)
        guard !preferred.isEmpty else { return Subject.allCases }

        var result = Subject.allCases.filter { preferred.contains($0.rawValue) }
        if let current = Subject.allCases.first(where: { $0.rawValue == currentSubject }),
           !result.contains(current) {
            result.append(current)
        }
        return result
    }

    static func appendingTags(_ rawNewTags: String, to tagsText: String) -> String {
        let nextTags = MistakeTagParser.appending(MistakeTagParser.parse(rawNewTags), to: MistakeTagParser.parse(tagsText))
        return MistakeTagParser.serialize(nextTags)
    }

    static func removingTag(_ tag: String, from tagsText: String) -> String {
        MistakeTagParser.serialize(MistakeTagParser.parse(tagsText).filter { $0 != tag })
    }
}
