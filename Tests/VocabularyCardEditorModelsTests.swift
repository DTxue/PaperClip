import Foundation

@main
struct VocabularyCardEditorModelsTests {
    static func main() {
        testDraftRequiresTermAndDefinition()
        testSnapshotTrimsRequiredFields()
        print("VocabularyCardEditorModelsTests: 4 passed")
    }

    private static func testDraftRequiresTermAndDefinition() {
        var draft = VocabularyCardEditDraft()
        expect(!draft.canSave)

        draft.term = "word"
        expect(!draft.canSave)

        draft.definition = "meaning"
        expect(draft.canSave)
    }

    private static func testSnapshotTrimsRequiredFields() {
        var draft = VocabularyCardEditDraft()
        draft.term = "  word  "
        draft.definition = "\nmeaning\t"
        draft.example = " keep spacing "

        let snapshot = draft.snapshot
        expect(snapshot.term == "word")
        expect(snapshot.definition == "meaning")
        expect(snapshot.example == " keep spacing ")
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
