import Foundation

enum ReviewSubmissionRenderError: LocalizedError {
    case invalidPDF
    case invalidSelection
    case unsupportedPage
    case imageTooLarge
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidPDF:
            "PDF 文件无法读取。"
        case .invalidSelection:
            "请选择 1 至 \(ReviewSubmissionRenderer.maximumPageCount) 页。"
        case .unsupportedPage:
            "所选页面无法渲染。"
        case .imageTooLarge:
            "所选页面比例导致长图尺寸过大，请减少页数后重试。"
        case .encodingFailed:
            "长图无法编码为 JPEG。"
        }
    }
}
