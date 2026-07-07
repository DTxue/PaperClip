import UIKit
@preconcurrency import PDFKit
import PencilKit

enum PDFPageLongImageRenderer {
    private static let preferredPixelWidth: CGFloat = 1_500
    private static let minimumPixelWidth: CGFloat = 600
    private static let maximumPixelHeight: CGFloat = 24_000
    private static let maximumPixelCount: CGFloat = 32_000_000

    enum RenderError: LocalizedError {
        case imageTooLarge

        var errorDescription: String? {
            switch self {
            case .imageTooLarge:
                "所选页面过多，长图尺寸过大，请减少页数后重试。"
            }
        }
    }

    /// 将选中页渲染为高清长图（含手写叠加）。
    /// 按总长宽比动态限制输出像素，避免多页导出分配超大 context 引发黑图或内存峰值。
    static func renderJPEG(
        documentURL: URL,
        pageIndices: [Int],
        drawings: [Int: Data],
        canvasSizes: [Int: CGSize],
        screenScale: CGFloat
    ) throws -> Data {
        guard !pageIndices.isEmpty else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let pdfDocument = try PDFRenderSupport.document(at: documentURL)

        let pageSources = PDFPageLongImageSource.sources(
            in: pdfDocument,
            pageIndices: pageIndices
        )
        let pageInputs = PDFPageLongImageSource.pageInputs(from: pageSources)

        let outputScale = max(screenScale, 1)
        guard let constrainedLayout = PDFLongImageLayoutSupport.constrainedStackLayout(
            pageInputs: pageInputs,
            preferredPixelWidth: preferredPixelWidth,
            minimumPixelWidth: minimumPixelWidth,
            maximumPixelHeight: maximumPixelHeight,
            maximumPixelCount: maximumPixelCount,
            outputScale: outputScale
        ) else {
            throw RenderError.imageTooLarge
        }
        let targetPixelW = constrainedLayout.targetPixelWidth
        let stackLayout = constrainedLayout.stackLayout
        guard !pageSources.isEmpty, pageSources.count == stackLayout.pages.count else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let stripImage = PDFRenderSupport.opaqueImage(
            size: stackLayout.outputSize,
            scale: outputScale
        ) { context in
            PDFDrawingRenderSupport.fillWhiteBackground(
                in: CGRect(origin: .zero, size: stackLayout.outputSize),
                context: context
            )

            for offset in pageSources.indices {
                let source = pageSources[offset]
                let index = source.index
                let mediaBox = source.mediaBox
                let destination = stackLayout.pages[offset].destination
                PDFPageDrawingRenderer.drawPage(
                    source.page,
                    mediaBox: mediaBox,
                    destination: destination,
                    drawingData: drawings[index],
                    canvasSize: canvasSizes[index] ?? mediaBox.size,
                    outputPixelWidth: targetPixelW,
                    context: context
                )
            }
        }

        return try PDFRenderSupport.jpegData(from: stripImage, profile: .longPDFImage)
    }
}
