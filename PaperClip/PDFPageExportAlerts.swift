import Foundation

enum PDFPageExportDestinationFailureAlert {
    static func alert(
        destination: PDFPageExportDestination,
        error: Error
    ) -> AppAlert {
        switch destination {
        case .share:
            AppAlert(title: "导出失败", error: error)
        case .photoLibrary:
            AppAlert(title: "保存失败", message: error.localizedDescription)
        }
    }
}
