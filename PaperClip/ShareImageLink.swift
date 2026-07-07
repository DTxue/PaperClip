import SwiftUI

struct ShareImageLink<LabelContent: View>: View {
    let request: ShareImageRequest
    let previewTitle: String
    @ViewBuilder let label: () -> LabelContent

    var body: some View {
        ShareLink(
            item: request,
            preview: SharePreview(
                previewTitle,
                image: request.image.map(Image.init(uiImage:))
                    ?? Image(systemName: "photo")
            ),
            label: label
        )
    }
}
