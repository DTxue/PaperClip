import SwiftUI

struct PDFPageExportContentView: View {
    let pageCount: Int?
    let generatedImage: ShareImageRequest?
    @Binding var selectedIndices: Set<Int>

    var body: some View {
        if let image = generatedImage?.image {
            ReviewLongImagePreview(
                image: image,
                accessibilityLabel: "待分享的页面长图"
            )
        } else if pageCount == nil {
            ProgressView("加载中…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if pageCount == 0 {
            ContentUnavailableView("无页面", systemImage: "doc.slash")
        } else {
            PDFPageSelectionGrid(
                pageCount: pageCount ?? 0,
                selectedIndices: $selectedIndices
            )
        }
    }
}
