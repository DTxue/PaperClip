enum PDFSelectionAction {
    case saveMistake
    case share
}

enum PDFSelectionHandle: CaseIterable {
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
    case left
}

enum PDFSelectionAdjustment {
    case creating
    case moving
    case resizing(PDFSelectionHandle)
}
