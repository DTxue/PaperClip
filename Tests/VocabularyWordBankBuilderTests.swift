@main
struct VocabularyWordBankBuilderTests {
    static func main() {
        testBuildNormalizesAndCapsTiles()
        testSentenceTilesSplitOnWhitespace()
        testSentenceTilesPreserveRepeatedWords()
        print("VocabularyWordBankBuilderTests: 3 passed")
    }

    private static func testBuildNormalizesAndCapsTiles() {
        let tiles = VocabularyWordBankBuilder.build(
            correctTiles: [" run ", "", "running"],
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

    private static func testSentenceTilesSplitOnWhitespace() {
        expect(
            VocabularyWordBankBuilder.sentenceTiles(
                "  Take   care of yourself. "
            ) == ["Take", "care", "of", "yourself."]
        )
    }

    private static func testSentenceTilesPreserveRepeatedWords() {
        let correctTiles = VocabularyWordBankBuilder.sentenceTiles(
            "I had had enough"
        )
        let tiles = VocabularyWordBankBuilder.build(
            correctTiles: correctTiles,
            distractorTiles: []
        )

        expect(tiles.map(\.text) == ["I", "had", "had", "enough"])
        expect(tiles.map(\.id) == [0, 1, 2, 3])
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
