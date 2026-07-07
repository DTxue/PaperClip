@main
struct VocabularyWordBankBuilderTests {
    static func main() {
        testBuildNormalizesAndCapsTiles()
        print("VocabularyWordBankBuilderTests: 1 passed")
    }

    private static func testBuildNormalizesAndCapsTiles() {
        let tiles = VocabularyWordBankBuilder.build(
            correctTiles: [" run ", "run", "", "running"],
            distractorTiles: [" jump ", "run", "swim", "jump", "read", "write"],
            maximumDistractorCount: 3
        )

        expect(tiles == [
            VocabularyWordBankTile(id: 0, text: "run"),
            VocabularyWordBankTile(id: 1, text: "running"),
            VocabularyWordBankTile(id: 1000, text: "jump"),
            VocabularyWordBankTile(id: 1001, text: "swim"),
            VocabularyWordBankTile(id: 1002, text: "read")
        ])
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
