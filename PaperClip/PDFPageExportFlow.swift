import CoreGraphics
import Foundation

enum PDFPageExportResult {
    case share(Data)
    case savedToPhotoLibrary
    case photoLibraryDenied
}

enum PDFPageExportFlow {
    static func export(
        destination: PDFPageExportDestination,
        request: PDFPageExportRequest
    ) async throws -> PDFPageExportResult {
        let data = try await renderJPEG(request)

        switch destination {
        case .share:
            return .share(data)
        case .photoLibrary:
            switch try await PhotoLibraryImageWriter.saveJPEGData(data) {
            case .saved:
                return .savedToPhotoLibrary
            case .denied:
                return .photoLibraryDenied
            }
        }
    }

    static func renderJPEG(_ request: PDFPageExportRequest) async throws -> Data {
        let renderInput = request.renderInput
        return try await Task.detached(priority: .userInitiated) {
            try PDFPageLongImageRenderer.renderJPEG(
                documentURL: request.documentURL,
                pageIndices: renderInput.pageIndices,
                drawings: renderInput.drawings,
                canvasSizes: renderInput.canvasSizes,
                screenScale: request.screenScale
            )
        }.value
    }
}

extension PDFPageExportResult {
    func apply(
        to generatedImageData: inout Data?,
        alert: inout AppAlert?
    ) {
        switch self {
        case let .share(data):
            generatedImageData = data
        case .savedToPhotoLibrary:
            alert = AppAlert(title: "已保存到相册", message: "页面长图已写入系统相册。")
        case .photoLibraryDenied:
            alert = AppAlert(title: "无法访问相册", message: "请在「设置 → 隐私与安全性 → 照片」中允许 PaperClip 写入照片。")
        }
    }
}
