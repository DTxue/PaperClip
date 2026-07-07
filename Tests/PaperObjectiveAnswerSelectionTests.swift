import Foundation

@main
struct PaperObjectiveAnswerSelectionTests {
    static func main() {
        expect(PaperObjectiveAnswerSelection.labels(in: "a, C、d") == ["A", "C", "D"])
        expect(PaperObjectiveAnswerSelection.labels(in: "Ａ，b") == ["Ａ", "B"])
        expect(
            PaperObjectiveAnswerSelection.answer(
                from: ["D", "A", "C"],
                orderedBy: ["A", "B", "C", "D"]
            ) == "A,C,D"
        )
        expect(
            PaperObjectiveAnswerSelection.answer(
                from: ["A", "Z"],
                orderedBy: ["A", "B", "C", "D"]
            ) == "A"
        )

        print("PaperObjectiveAnswerSelectionTests: 4 passed")
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError("Expectation failed", file: file, line: line)
        }
    }
}
