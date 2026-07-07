import PencilKit

@MainActor
final class WritingDrawingStore {
    var drawing = PKDrawing() {
        didSet { revision &+= 1 }
    }
    private(set) var revision = 0
}
