import Foundation
import PencilKit

enum DrawingDataSupport {
    static func emptyData() -> Data {
        PKDrawing().dataRepresentation()
    }

    static func data(from drawing: PKDrawing) -> Data {
        drawing.dataRepresentation()
    }

    static func drawing(from data: Data) -> PKDrawing? {
        guard !data.isEmpty else { return nil }
        return try? PKDrawing(data: data)
    }

    static func drawingOrEmpty(from data: Data) -> PKDrawing {
        drawing(from: data) ?? PKDrawing()
    }

    static func hasInk(_ drawing: PKDrawing) -> Bool {
        !drawing.strokes.isEmpty
    }

}
