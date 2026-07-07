import UIKit

enum ImageRenderSupport {
    static func opaqueRendererFormat(scale: CGFloat = 1) -> UIGraphicsImageRendererFormat {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        return format
    }

    static func opaqueImage(
        size: CGSize,
        scale: CGFloat = 1,
        actions: (UIGraphicsImageRendererContext) -> Void
    ) -> UIImage {
        UIGraphicsImageRenderer(
            size: size,
            format: opaqueRendererFormat(scale: scale)
        ).image(actions: actions)
    }

    static func normalizedOpaqueImage(
        _ image: UIImage,
        maximumDimension: CGFloat
    ) -> UIImage {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image }
        let scale = min(maximumDimension / size.width, maximumDimension / size.height, 1)
        if scale == 1,
           image.imageOrientation == .up,
           !hasAlpha(image) {
            return image
        }

        let targetSize = CGSize(
            width: (size.width * scale).rounded(),
            height: (size.height * scale).rounded()
        )
        return opaqueImage(size: targetSize) { context in
            fillWhiteBackground(
                in: CGRect(origin: .zero, size: targetSize),
                context: context
            )
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    static func fillWhiteBackground(
        in rect: CGRect,
        context: UIGraphicsImageRendererContext
    ) {
        fill(.white, in: rect, context: context)
    }

    static func fill(
        _ color: UIColor,
        in rect: CGRect,
        context: UIGraphicsImageRendererContext
    ) {
        color.setFill()
        context.fill(rect)
    }

    private static func hasAlpha(_ image: UIImage) -> Bool {
        guard let alphaInfo = image.cgImage?.alphaInfo else { return true }
        switch alphaInfo {
        case .none, .noneSkipLast, .noneSkipFirst:
            return false
        default:
            return true
        }
    }
}
