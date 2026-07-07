import CoreGraphics
import Foundation
import UIKit

/// 后台降采样 + 内存缓存。键包含目标尺寸与裁剪范围，保证不同尺寸请求互不污染。
enum LocalImageLoader {
    nonisolated(unsafe) private static let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 220
        c.totalCostLimit = 160 * 1024 * 1024
        return c
    }()

    static func load(path: String) async -> UIImage? {
        await load(path: path, normalizedCrop: nil, maxPixelSize: nil)
    }

    static func load(
        path: String,
        normalizedCrop cropString: String?,
        maxPixelSize: CGFloat? = nil
    ) async -> UIImage? {
        let key = LocalImageCacheKey.make(path: path, crop: cropString, maxPixelSize: maxPixelSize)
        if let hit = cache.object(forKey: key as NSString) { return hit }
        let sourceKey = LocalImageCacheKey.make(path: path, crop: nil, maxPixelSize: maxPixelSize)
        let image = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            guard let source = loadSourceImage(path: path, maxPixelSize: maxPixelSize) else { return nil }
            guard let cropString,
                  let norm = NormalizedCropString.parse(cropString),
                  norm.width > 0,
                  norm.height > 0,
                  let cgImage = source.cgImage else {
                return source
            }

            let pixelWidth = CGFloat(cgImage.width)
            let pixelHeight = CGFloat(cgImage.height)
            let crop = CGRect(
                x: norm.minX * pixelWidth,
                y: norm.minY * pixelHeight,
                width: norm.width * pixelWidth,
                height: norm.height * pixelHeight
            ).integral.intersection(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))

            guard !crop.isNull,
                  crop.width > 0,
                  crop.height > 0,
                  let cropped = cgImage.cropping(to: crop) else {
                return source
            }
            return UIImage(cgImage: cropped, scale: source.scale, orientation: source.imageOrientation)
        }.value
        if let image, key != sourceKey {
            cache.setObject(image, forKey: key as NSString, cost: ImageCacheSupport.cost(image))
        }
        return image
    }

    static func cached(
        path: String,
        normalizedCrop cropString: String?,
        maxPixelSize: CGFloat? = nil
    ) -> UIImage? {
        let key = LocalImageCacheKey.make(path: path, crop: cropString, maxPixelSize: maxPixelSize)
        return cache.object(forKey: key as NSString)
    }

    private static func loadSourceImage(path: String, maxPixelSize: CGFloat?) -> UIImage? {
        let fullKey = LocalImageCacheKey.make(path: path, crop: nil, maxPixelSize: maxPixelSize)
        if let cached = cache.object(forKey: fullKey as NSString) {
            return cached
        }
        let image: UIImage?
        if let maxPixelSize {
            image = ImageCacheSupport.downsample(path: path, maxPixel: maxPixelSize)
        } else {
            image = UIImage(contentsOfFile: path)
        }
        guard let image else { return nil }
        cache.setObject(image, forKey: fullKey as NSString, cost: ImageCacheSupport.cost(image))
        return image
    }
}
