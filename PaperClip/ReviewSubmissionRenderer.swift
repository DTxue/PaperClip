import PDFKit
import PencilKit
import UIKit

// Apple 没有将多个 PDF 页面和独立 PencilKit 图层合成为单张长图的系统 API。
// 此渲染器只承担批阅图片合成：PDFKit 负责页面渲染，PKDrawing 负责正式答案图层；
// 页面选择、预览和分享仍使用 SwiftUI List、NavigationStack 与 ShareLink。
// 合成过程不修改原 PDF 或手写持久化数据，也不引入自定义手势。
enum ReviewSubmissionRenderer {
    static let maximumPageCount = ReviewSubmissionSelectionSupport.maximumPageCount

    static func hasVisibleDrawing(_ data: Data?) -> Bool {
        PDFDrawingRenderSupport.visibleDrawing(from: data) != nil
    }

    static func render(_ request: ReviewSubmissionGenerationRequest) throws -> Data {
        try render(
            pdfURL: request.pdfURL,
            pageIndices: request.pageIndices,
            drawings: request.drawings
        )
    }

    static func render(
        pdfURL: URL,
        pageIndices: [Int],
        drawings: [Int: Data]
    ) throws -> Data {
        guard let document = try? PDFRenderSupport.document(at: pdfURL) else {
            throw ReviewSubmissionRenderError.invalidPDF
        }
        let plan = try ReviewSubmissionRenderPlan.make(
            document: document,
            pageIndices: pageIndices,
            maximumPageCount: maximumPageCount
        )

        let image = PDFRenderSupport.opaqueImage(size: plan.outputLayout.outputSize) { context in
            ReviewSubmissionPageDrawer.draw(
                document: document,
                plan: plan,
                drawings: drawings,
                context: context
            )
        }

        guard let data = try? PDFRenderSupport.jpegData(from: image, profile: .reviewSubmission) else {
            throw ReviewSubmissionRenderError.encodingFailed
        }
        return data
    }
}
