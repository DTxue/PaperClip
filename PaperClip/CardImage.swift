import SwiftUI

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

    var body: some View {
        AsyncLocalImage(
            path: url.path,
            maxPixelSize: maxPixelSize
        ) { image in
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } placeholder: {
            ZStack {
                Rectangle()
                    .fill(.quaternary)
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
