import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

@main
struct KnowledgePointVocabularyTests {
    static func main() {
        let mathPoints = KnowledgePointVocabulary.points(for: Subject.math.rawValue)
        expect(!mathPoints.isEmpty, "math vocabulary should not be empty")
        expect(mathPoints.filter { $0 == "公式法" }.count == 1, "points should be de-duplicated")
        expect(KnowledgePointVocabulary.points(for: "不存在").isEmpty, "unknown subject should be empty")

        let hintLines = KnowledgePointVocabulary.promptHint().split(separator: "\n").map(String.init)
        expect(hintLines.count == 9, "prompt should include supported subjects")
        expect(hintLines.first?.hasPrefix("数学：") == true, "prompt should start with math")
        expect(hintLines[1].hasPrefix("物理："), "prompt should keep subject order")
        for line in hintLines {
            let parts = line.split(separator: "：", maxSplits: 1).map(String.init)
            expect(parts.count == 2, "prompt line should contain subject and points")
            expect(parts[1].split(separator: "、").count <= 30, "prompt line should cap points")
        }

        print("KnowledgePointVocabularyTests: 7 passed")
    }
}
