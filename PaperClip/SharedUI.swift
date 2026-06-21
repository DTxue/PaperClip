import SwiftUI
import UIKit
import ImageIO

// MARK: - 统一错误提示

extension View {
    /// 统一的错误/提示弹窗。集中处理 `AppAlert`，消除各视图重复的 `Alert(...)` 样板。
    /// 内部仍使用系统 `alert(item:)`，不引入任何自定义弹窗实现。
    func appAlert(_ alert: Binding<AppAlert?>) -> some View {
        self.alert(item: alert) { value in
            Alert(
                title: Text(value.title),
                message: Text(value.message),
                dismissButton: .default(Text("好"))
            )
        }
    }
}

// MARK: - 卡片缩略图（缓存 + 降采样）

/// 错题卡图片的统一渲染视图。
///
/// 原生 API 评估（满足 CLAUDE.md §3 自定义准入说明）：
/// - 已检查 `Image(uiImage:)` 与 `AsyncImage`。`AsyncImage` 面向远程 URL，
///   不缓存、不降采样，每次出现都会重新解码原始大图；直接 `UIImage(contentsOfFile:)`
///   则在视图 body 内于主线程同步解码整张 PNG，在滚动网格/列表中造成卡顿与内存峰值。
/// - 系统未提供「本地文件 + 降采样 + 内存缓存」的等价能力，故自定义此视图。
/// - 业务职责：仅承担错题卡缩略图/预览图的高效加载，不替代任何系统控件。
/// - 无障碍：保留调用方设置的 `accessibilityLabel`；占位符使用 SF Symbols。
struct CardImage: View {
    let url: URL
    var contentMode: ContentMode = .fit
    /// 目标最大像素边长，用于 ImageIO 降采样；缩略图 600 足够，大图预览可传更大值。
    var maxPixelSize: CGFloat = 600

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .task(id: cacheKey) {
            if let cached = ThumbnailCache.cached(cacheKey) {
                image = cached
                return
            }
            image = nil
            image = await ThumbnailCache.load(path: url.path, maxPixel: maxPixelSize)
        }
    }

    private var cacheKey: String { ThumbnailCache.key(path: url.path, maxPixel: maxPixelSize) }
}

/// 后台降采样 + 内存缓存。键包含目标尺寸，保证不同尺寸请求互不污染。
enum ThumbnailCache {
    // NSCache 自身线程安全，可在并发上下文中共享；Swift 6 下用 nonisolated(unsafe) 显式声明。
    nonisolated(unsafe) private static let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 200
        return c
    }()

    static func key(path: String, maxPixel: CGFloat) -> String {
        "\(path)@\(Int(maxPixel))"
    }

    static func cached(_ key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    static func load(path: String, maxPixel: CGFloat) async -> UIImage? {
        let key = key(path: path, maxPixel: maxPixel)
        if let hit = cache.object(forKey: key as NSString) { return hit }
        let decoded = await Task.detached(priority: .userInitiated) {
            downsample(path: path, maxPixel: maxPixel)
        }.value
        if let decoded {
            cache.setObject(decoded, forKey: key as NSString)
        }
        return decoded
    }

    private static func downsample(path: String, maxPixel: CGFloat) -> UIImage? {
        let fileURL = URL(fileURLWithPath: path)
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, sourceOptions) else {
            return nil
        }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
