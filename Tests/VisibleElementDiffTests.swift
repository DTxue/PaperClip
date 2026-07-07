import Foundation

@main
struct VisibleElementDiffTests {
    static func main() {
        let removed = VisibleElementDiff.elementsToRemove(
            existing: [1, 2, 3, 4],
            visible: [2, 4]
        )
        expect(removed == [1, 3], "diff should preserve existing order and remove invisible elements")
        print("VisibleElementDiffTests: 1 passed")
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError(message, file: file, line: line)
        }
    }
}
