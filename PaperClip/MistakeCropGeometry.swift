import CoreGraphics

enum MistakeCropHandle {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing
}

enum MistakeCropGeometry {
    static func aspectFitRect(imageSize: CGSize, containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0,
              imageSize.height > 0,
              containerSize.width > 0,
              containerSize.height > 0
        else { return .zero }

        let scale = min(
            containerSize.width / imageSize.width,
            containerSize.height / imageSize.height
        )
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: (containerSize.width - size.width) / 2,
            y: (containerSize.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }

    static func normalizedSelection(_ selection: CGRect, in imageRect: CGRect) -> CGRect? {
        guard imageRect.width > 0, imageRect.height > 0 else { return nil }
        let clipped = selection.standardized.intersection(imageRect)
        guard !clipped.isNull, clipped.width > 0, clipped.height > 0 else { return nil }
        return CGRect(
            x: (clipped.minX - imageRect.minX) / imageRect.width,
            y: (clipped.minY - imageRect.minY) / imageRect.height,
            width: clipped.width / imageRect.width,
            height: clipped.height / imageRect.height
        )
    }

    static func selectionRect(from normalized: CGRect, in imageRect: CGRect) -> CGRect {
        CGRect(
            x: imageRect.minX + normalized.minX * imageRect.width,
            y: imageRect.minY + normalized.minY * imageRect.height,
            width: normalized.width * imageRect.width,
            height: normalized.height * imageRect.height
        )
    }

    static func moving(
        _ selection: CGRect,
        translation: CGSize,
        within imageRect: CGRect
    ) -> CGRect {
        let x = min(
            max(selection.minX + translation.width, imageRect.minX),
            imageRect.maxX - selection.width
        )
        let y = min(
            max(selection.minY + translation.height, imageRect.minY),
            imageRect.maxY - selection.height
        )
        return CGRect(origin: CGPoint(x: x, y: y), size: selection.size)
    }

    static func resizing(
        _ selection: CGRect,
        handle: MistakeCropHandle,
        translation: CGSize,
        within imageRect: CGRect,
        minimumSize: CGFloat = 44
    ) -> CGRect {
        var minX = selection.minX
        var minY = selection.minY
        var maxX = selection.maxX
        var maxY = selection.maxY

        switch handle {
        case .topLeading:
            minX = min(max(selection.minX + translation.width, imageRect.minX), maxX - minimumSize)
            minY = min(max(selection.minY + translation.height, imageRect.minY), maxY - minimumSize)
        case .topTrailing:
            maxX = max(min(selection.maxX + translation.width, imageRect.maxX), minX + minimumSize)
            minY = min(max(selection.minY + translation.height, imageRect.minY), maxY - minimumSize)
        case .bottomLeading:
            minX = min(max(selection.minX + translation.width, imageRect.minX), maxX - minimumSize)
            maxY = max(min(selection.maxY + translation.height, imageRect.maxY), minY + minimumSize)
        case .bottomTrailing:
            maxX = max(min(selection.maxX + translation.width, imageRect.maxX), minX + minimumSize)
            maxY = max(min(selection.maxY + translation.height, imageRect.maxY), minY + minimumSize)
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    static func pixelCropRect(normalizedSelection: CGRect, pixelSize: CGSize) -> CGRect? {
        guard pixelSize.width > 0, pixelSize.height > 0 else { return nil }
        let unitRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let normalized = normalizedSelection.standardized.intersection(unitRect)
        guard !normalized.isNull, normalized.width > 0, normalized.height > 0 else { return nil }

        let scaled = CGRect(
            x: normalized.minX * pixelSize.width,
            y: normalized.minY * pixelSize.height,
            width: normalized.width * pixelSize.width,
            height: normalized.height * pixelSize.height
        ).integral
        return scaled.intersection(CGRect(origin: .zero, size: pixelSize))
    }
}
