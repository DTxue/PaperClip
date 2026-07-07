import CoreGraphics
import Foundation

struct PDFPageExportRenderInput {
    let pageIndices: [Int]
    let drawings: [Int: Data]
    let canvasSizes: [Int: CGSize]
}

extension PDFPageExportSelectionSupport {
    static func renderInput(
        selectedIndices: Set<Int>,
        drawings: [Int: Data],
        canvasSizes: [Int: CGSize]
    ) -> PDFPageExportRenderInput {
        let pageIndices = selectedIndices.sorted()
        var selectedDrawings: [Int: Data] = [:]
        var selectedCanvasSizes: [Int: CGSize] = [:]
        selectedDrawings.reserveCapacity(min(pageIndices.count, drawings.count))
        selectedCanvasSizes.reserveCapacity(min(pageIndices.count, canvasSizes.count))

        for index in pageIndices {
            if let drawing = drawings[index] {
                selectedDrawings[index] = drawing
            }
            if let canvasSize = canvasSizes[index] {
                selectedCanvasSizes[index] = canvasSize
            }
        }

        return PDFPageExportRenderInput(
            pageIndices: pageIndices,
            drawings: selectedDrawings,
            canvasSizes: selectedCanvasSizes
        )
    }
}
