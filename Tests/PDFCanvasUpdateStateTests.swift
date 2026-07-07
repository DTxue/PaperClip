import CoreGraphics
import Foundation

@main
struct PDFCanvasUpdateStateTests {
    static func main() {
        testInitialSnapshotSchedulesLayoutOnly()
        testRepeatedSnapshotHasNoChanges()
        testLayoutInputChangeDoesNotTriggerCommands()
        testCommandTokenChangesAreReportedIndividually()
        print("PDFCanvasUpdateStateTests: 4 passed")
    }

    private static func testInitialSnapshotSchedulesLayoutOnly() {
        var state = PDFCanvasUpdateState()

        let changes = state.consume(makeSnapshot())

        expect(changes.needsLayout)
        expect(!changes.selectionActionChanged)
        expect(!changes.cancelSelectionChanged)
        expect(!changes.undoChanged)
        expect(!changes.redoChanged)
        expect(!changes.clearAnswersChanged)
        expect(!changes.reloadDrawingsChanged)
    }

    private static func testRepeatedSnapshotHasNoChanges() {
        var state = PDFCanvasUpdateState()
        let snapshot = makeSnapshot()
        _ = state.consume(snapshot)

        let changes = state.consume(snapshot)

        expect(changes == PDFCanvasUpdateChanges.noChanges)
    }

    private static func testLayoutInputChangeDoesNotTriggerCommands() {
        var state = PDFCanvasUpdateState()
        _ = state.consume(makeSnapshot())

        let changes = state.consume(
            makeSnapshot(url: URL(fileURLWithPath: "/tmp/other.pdf"))
        )

        expect(changes.needsLayout)
        expect(!changes.hasCommandChanges)
    }

    private static func testCommandTokenChangesAreReportedIndividually() {
        var state = PDFCanvasUpdateState()
        _ = state.consume(makeSnapshot())

        let changes = state.consume(
            makeSnapshot(
                commandTokens: PDFCanvasCommandTokens(
                    selectionAction: 1,
                    cancelSelection: 0,
                    undo: 0,
                    redo: 2,
                    clearAnswers: 0,
                    reloadDrawings: 3
                )
            )
        )

        expect(!changes.needsLayout)
        expect(changes.selectionActionChanged)
        expect(!changes.cancelSelectionChanged)
        expect(!changes.undoChanged)
        expect(changes.redoChanged)
        expect(!changes.clearAnswersChanged)
        expect(changes.reloadDrawingsChanged)
    }

    private static func makeSnapshot(
        url: URL = URL(fileURLWithPath: "/tmp/source.pdf"),
        commandTokens: PDFCanvasCommandTokens = PDFCanvasCommandTokens(
            selectionAction: 0,
            cancelSelection: 0,
            undo: 0,
            redo: 0,
            clearAnswers: 0,
            reloadDrawings: 0
        )
    ) -> PDFCanvasUpdateSnapshot {
        PDFCanvasUpdateSnapshot(
            layoutInputs: PDFCanvasLayoutInputs(
                url: url,
                gradeStamps: [
                    PDFGradeStamp(
                        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                        pageIndex: 0,
                        isCorrect: true,
                        normalizedAnchor: CGPoint(x: 0.5, y: 0.5),
                        confidence: 0.9
                    )
                ]
            ),
            commandTokens: commandTokens
        )
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

private extension PDFCanvasUpdateChanges {
    static let noChanges = PDFCanvasUpdateChanges(
        needsLayout: false,
        selectionActionChanged: false,
        cancelSelectionChanged: false,
        undoChanged: false,
        redoChanged: false,
        clearAnswersChanged: false,
        reloadDrawingsChanged: false
    )

    var hasCommandChanges: Bool {
        selectionActionChanged
            || cancelSelectionChanged
            || undoChanged
            || redoChanged
            || clearAnswersChanged
            || reloadDrawingsChanged
    }
}
