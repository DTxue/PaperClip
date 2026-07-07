import SwiftUI
import UIKit

struct AsyncLocalImage<Content: View, Placeholder: View>: View {
    let path: String
    var normalizedCrop: String? = nil
    var maxPixelSize: CGFloat = 1400
    let content: (UIImage) -> Content
    let placeholder: () -> Placeholder

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                content(image)
            } else {
                placeholder()
            }
        }
        .task(id: taskID) {
            if let cached = LocalImageLoader.cached(
                path: path,
                normalizedCrop: normalizedCrop,
                maxPixelSize: maxPixelSize
            ) {
                image = cached
                return
            }
            image = nil
            let loadedImage = await LocalImageLoader.load(
                path: path,
                normalizedCrop: normalizedCrop,
                maxPixelSize: maxPixelSize
            )
            guard !Task.isCancelled else { return }
            image = loadedImage
        }
    }

    private var taskID: String {
        LocalImageCacheKey.make(
            path: path,
            crop: normalizedCrop,
            maxPixelSize: maxPixelSize
        )
    }
}
