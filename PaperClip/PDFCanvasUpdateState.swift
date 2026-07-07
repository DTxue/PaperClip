import Foundation

struct PDFCanvasCommandTokens: Equatable {
    let selectionAction: Int
    let cancelSelection: Int
    let undo: Int
    let redo: Int
    let clearAnswers: Int
    let reloadDrawings: Int
}

struct PDFCanvasUpdateSnapshot: Equatable {
    let layoutInputs: PDFCanvasLayoutInputs
    let commandTokens: PDFCanvasCommandTokens
}

struct PDFCanvasLayoutInputs: Equatable {
    let url: URL
    let gradeStamps: [PDFGradeStamp]
}

struct PDFCanvasUpdateState {
    private var lastSnapshot: PDFCanvasUpdateSnapshot?

    mutating func consume(_ snapshot: PDFCanvasUpdateSnapshot) -> PDFCanvasUpdateChanges {
        guard let lastSnapshot else {
            self.lastSnapshot = snapshot
            return PDFCanvasUpdateChanges(
                needsLayout: true,
                selectionActionChanged: false,
                cancelSelectionChanged: false,
                undoChanged: false,
                redoChanged: false,
                clearAnswersChanged: false,
                reloadDrawingsChanged: false
            )
        }

        let changes = PDFCanvasUpdateChanges(
            needsLayout: snapshot.layoutInputs != lastSnapshot.layoutInputs,
            selectionActionChanged: snapshot.commandTokens.selectionAction != lastSnapshot.commandTokens.selectionAction,
            cancelSelectionChanged: snapshot.commandTokens.cancelSelection != lastSnapshot.commandTokens.cancelSelection,
            undoChanged: snapshot.commandTokens.undo != lastSnapshot.commandTokens.undo,
            redoChanged: snapshot.commandTokens.redo != lastSnapshot.commandTokens.redo,
            clearAnswersChanged: snapshot.commandTokens.clearAnswers != lastSnapshot.commandTokens.clearAnswers,
            reloadDrawingsChanged: snapshot.commandTokens.reloadDrawings != lastSnapshot.commandTokens.reloadDrawings
        )
        self.lastSnapshot = snapshot
        return changes
    }
}

struct PDFCanvasUpdateChanges: Equatable {
    let needsLayout: Bool
    let selectionActionChanged: Bool
    let cancelSelectionChanged: Bool
    let undoChanged: Bool
    let redoChanged: Bool
    let clearAnswersChanged: Bool
    let reloadDrawingsChanged: Bool
}
