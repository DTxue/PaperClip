import PencilKit

final class PDFPendingDrawingStore {
    private var drawingsByPage: [Int: PKDrawing] = [:]

    var isEmpty: Bool {
        drawingsByPage.isEmpty
    }

    func set(_ drawing: PKDrawing, for pageIndex: Int) {
        drawingsByPage[pageIndex] = drawing
    }

    func snapshotDrawingData() -> [Int: Data] {
        drawingsByPage.mapValues(DrawingDataSupport.data(from:))
    }

    func drain() -> [Int: PKDrawing] {
        let drawings = drawingsByPage
        drawingsByPage.removeAll(keepingCapacity: true)
        return drawings
    }

    func removePages(_ pageIndices: Set<Int>) {
        for pageIndex in pageIndices {
            drawingsByPage[pageIndex] = nil
        }
    }

    func removeAll() {
        drawingsByPage.removeAll(keepingCapacity: true)
    }
}
