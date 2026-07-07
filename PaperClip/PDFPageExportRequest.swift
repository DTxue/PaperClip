import CoreGraphics
import Foundation

struct PDFPageExportRequest {
    let documentURL: URL
    let selectedIndices: Set<Int>
    let drawings: [Int: Data]
    let canvasSizes: [Int: CGSize]
    let screenScale: CGFloat

    var renderInput: PDFPageExportRenderInput {
        PDFPageExportSelectionSupport.renderInput(
            selectedIndices: selectedIndices,
            drawings: drawings,
            canvasSizes: canvasSizes
        )
    }
}
