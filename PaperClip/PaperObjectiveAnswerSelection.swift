import Foundation

enum PaperObjectiveAnswerSelection {
    static func labels(in answer: String) -> Set<String> {
        var labels: Set<String> = []
        for rawLabel in answer.components(separatedBy: CharacterSet(charactersIn: ",，、 ")) {
            let label = rawLabel.uppercased()
            if !label.isEmpty {
                labels.insert(label)
            }
        }
        return labels
    }

    static func answer(from labels: Set<String>, orderedBy options: [String]) -> String {
        options
            .filter { labels.contains($0) }
            .joined(separator: ",")
    }
}
