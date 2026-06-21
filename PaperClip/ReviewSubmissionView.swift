import SwiftUI
import PDFKit
import PencilKit

struct ReviewSubmissionView: View {
    let documentTitle: String
    let pdfURL: URL
    let drawings: [Int: Data]

    @Environment(\.dismiss) private var dismiss

    @State private var selectedPages: Set<Int>
    @State private var generatedImage: ShareImageRequest?
    @State private var isGenerating = false
    @State private var alert: AppAlert?

    private let pageCount: Int

    init(documentTitle: String, pdfURL: URL, drawings: [Int: Data]) {
        self.documentTitle = documentTitle
        self.pdfURL = pdfURL
        self.drawings = drawings

        let count = PDFDocument(url: pdfURL)?.pageCount ?? 0
        pageCount = count

        let answeredPages = drawings.keys
            .filter {
                (0 ..< count).contains($0)
                    && Self.hasVisibleDrawing(drawings[$0])
            }
            .sorted()
        let initialPages = answeredPages.isEmpty
            ? Array(0 ..< min(count, 1))
            : Array(answeredPages.prefix(ReviewSubmissionRenderer.maximumPageCount))
        _selectedPages = State(initialValue: Set(initialPages))
    }

    var body: some View {
        NavigationStack {
            Group {
                if let generatedImage, let image = generatedImage.image {
                    ReviewLongImagePreview(image: image)
                } else {
                    pageSelection
                }
            }
            .navigationTitle(generatedImage == nil ? "选择批阅页面" : "批阅长图")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if generatedImage == nil {
                        Button("取消") { dismiss() }
                    } else {
                        Button("重新选择") { generatedImage = nil }
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if let generatedImage {
                        ShareLink(
                            item: generatedImage,
                            preview: SharePreview(
                                "\(documentTitle) · 批阅",
                                image: generatedImage.image.map(Image.init(uiImage:))
                                    ?? Image(systemName: "photo")
                            )
                        ) {
                            Label("分享", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button {
                            generateLongImage()
                        } label: {
                            Label("生成长图", systemImage: "photo.on.rectangle.angled")
                        }
                        .disabled(selectedPages.isEmpty || isGenerating)
                    }
                }
            }
            .overlay {
                if isGenerating {
                    ZStack {
                        Color.black.opacity(0.12).ignoresSafeArea()
                        ProgressView("正在合成 \(selectedPages.count) 页…")
                            .padding(24)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
        .appAlert($alert)
    }

    private var pageSelection: some View {
        List {
            Section {
                ForEach(0 ..< pageCount, id: \.self) { pageIndex in
                    let isSelected = selectedPages.contains(pageIndex)
                    Button {
                        togglePage(pageIndex)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(isSelected ? Color.accentColor : .secondary)

                            Text("第 \(pageIndex + 1) 页")
                                .foregroundStyle(.primary)

                            Spacer()

                            if Self.hasVisibleDrawing(drawings[pageIndex]) {
                                Label("有手写答案", systemImage: "pencil")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(
                        !isSelected
                            && selectedPages.count >= ReviewSubmissionRenderer.maximumPageCount
                    )
                    .accessibilityLabel(
                        "第 \(pageIndex + 1) 页，\(isSelected ? "已选择" : "未选择")"
                    )
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            } header: {
                Text("已选择 \(selectedPages.count) / \(ReviewSubmissionRenderer.maximumPageCount) 页")
            } footer: {
                Text("仅合成原 PDF 页面和当前练习的正式手写答案，不包含草稿板、错题框或其他界面元素。")
            }
        }
        .overlay {
            if pageCount == 0 {
                ContentUnavailableView(
                    "无法读取页面",
                    systemImage: "doc.questionmark",
                    description: Text("当前 PDF 没有可提交的页面。")
                )
            }
        }
    }

    private func togglePage(_ pageIndex: Int) {
        if selectedPages.contains(pageIndex) {
            selectedPages.remove(pageIndex)
        } else if selectedPages.count < ReviewSubmissionRenderer.maximumPageCount {
            selectedPages.insert(pageIndex)
        }
    }

    private func generateLongImage() {
        let pages = selectedPages.sorted()
        guard !pages.isEmpty else { return }

        isGenerating = true
        Task {
            do {
                let data = try await Task.detached(priority: .userInitiated) {
                    try ReviewSubmissionRenderer.render(
                        pdfURL: pdfURL,
                        pageIndices: pages,
                        drawings: drawings
                    )
                }.value
                generatedImage = ShareImageRequest(data: data)
            } catch {
                alert = AppAlert(title: "无法生成批阅图片", error: error)
            }
            isGenerating = false
        }
    }

    private static func hasVisibleDrawing(_ data: Data?) -> Bool {
        guard let data,
              let drawing = try? PKDrawing(data: data)
        else {
            return false
        }
        return !drawing.strokes.isEmpty
    }
}

private struct ReviewLongImagePreview: View {
    let image: UIImage

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 900)
                .background(.white)
                .shadow(color: .black.opacity(0.12), radius: 10, y: 3)
                .padding(20)
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .accessibilityLabel("待分享的批阅长图")
    }
}

// Apple 没有将多个 PDF 页面和独立 PencilKit 图层合成为单张长图的系统 API。
// 此渲染器只承担批阅图片合成：PDFKit 负责页面渲染，PKDrawing 负责正式答案图层；
// 页面选择、预览和分享仍使用 SwiftUI List、NavigationStack 与 ShareLink。
// 合成过程不修改原 PDF 或手写持久化数据，也不引入自定义手势。
enum ReviewSubmissionRenderer {
    static let maximumPageCount = 8

    private static let preferredWidth: CGFloat = 1_600
    private static let maximumHeight: CGFloat = 16_000
    private static let maximumPixelCount: CGFloat = 28_000_000
    private static let pageGap: CGFloat = 12

    private struct PageGeometry {
        let displayBox: PDFDisplayBox
        let displayBounds: CGRect
        let drawingBounds: CGRect
    }

    enum RenderError: LocalizedError {
        case invalidPDF
        case invalidSelection
        case unsupportedPage
        case imageTooLarge
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .invalidPDF:
                "PDF 文件无法读取。"
            case .invalidSelection:
                "请选择 1 至 \(maximumPageCount) 页。"
            case .unsupportedPage:
                "所选页面无法渲染。"
            case .imageTooLarge:
                "所选页面比例导致长图尺寸过大，请减少页数后重试。"
            case .encodingFailed:
                "长图无法编码为 PNG。"
            }
        }
    }

    static func render(
        pdfURL: URL,
        pageIndices: [Int],
        drawings: [Int: Data]
    ) throws -> Data {
        guard !pageIndices.isEmpty, pageIndices.count <= maximumPageCount else {
            throw RenderError.invalidSelection
        }
        guard let document = PDFDocument(url: pdfURL) else {
            throw RenderError.invalidPDF
        }

        let uniqueIndices = Array(Set(pageIndices)).sorted()
        guard uniqueIndices.count == pageIndices.count,
              uniqueIndices.allSatisfy({ (0 ..< document.pageCount).contains($0) })
        else {
            throw RenderError.invalidSelection
        }

        let pageGeometries: [PageGeometry] = try uniqueIndices.map { index in
            guard let page = document.page(at: index) else {
                throw RenderError.unsupportedPage
            }
            let mediaBounds = page.bounds(for: .mediaBox)
            let cropBounds = page.bounds(for: .cropBox)
            let hasCropBox = cropBounds.width > 0 && cropBounds.height > 0
            let displayBounds = hasCropBox ? cropBounds : mediaBounds
            guard mediaBounds.width > 0, mediaBounds.height > 0,
                  displayBounds.width > 0, displayBounds.height > 0
            else {
                throw RenderError.unsupportedPage
            }

            // PKCanvasView 当前按 mediaBox 覆盖 PDF 页面，PKDrawing 使用左上角坐标。
            // 导出 cropBox 时，将 PDF 的左下角坐标转换为对应的手写裁切区域。
            let drawingBounds = CGRect(
                x: displayBounds.minX - mediaBounds.minX,
                y: mediaBounds.maxY - displayBounds.maxY,
                width: displayBounds.width,
                height: displayBounds.height
            )
            return PageGeometry(
                displayBox: hasCropBox ? .cropBox : .mediaBox,
                displayBounds: displayBounds,
                drawingBounds: drawingBounds
            )
        }

        let totalAspectRatio = pageGeometries.reduce(CGFloat.zero) {
            $0 + $1.displayBounds.height / $1.displayBounds.width
        }
        let gapsHeight = pageGap * CGFloat(max(uniqueIndices.count - 1, 0))
        let widthByHeight = (maximumHeight - gapsHeight) / totalAspectRatio
        let widthByPixels = sqrt(maximumPixelCount / totalAspectRatio)
        let outputWidth = floor(min(preferredWidth, widthByHeight, widthByPixels))
        guard outputWidth >= 600 else {
            throw RenderError.imageTooLarge
        }

        let pageHeights = pageGeometries.map {
            ceil(outputWidth * $0.displayBounds.height / $0.displayBounds.width)
        }
        let outputHeight = pageHeights.reduce(0, +) + gapsHeight

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: outputWidth, height: outputHeight),
            format: format
        )

        let image = renderer.image { context in
            UIColor.systemGray5.setFill()
            context.fill(
                CGRect(x: 0, y: 0, width: outputWidth, height: outputHeight)
            )

            var y: CGFloat = 0
            for (offset, pageIndex) in uniqueIndices.enumerated() {
                guard let page = document.page(at: pageIndex) else { continue }
                let geometry = pageGeometries[offset]
                let pageHeight = pageHeights[offset]
                let destination = CGRect(
                    x: 0,
                    y: y,
                    width: outputWidth,
                    height: pageHeight
                )

                UIColor.white.setFill()
                context.fill(destination)
                page.thumbnail(
                    of: destination.size,
                    for: geometry.displayBox
                ).draw(in: destination)

                if let data = drawings[pageIndex],
                   !data.isEmpty,
                   let drawing = try? PKDrawing(data: data),
                   !drawing.strokes.isEmpty {
                    let drawingImage = drawing.image(
                        from: geometry.drawingBounds,
                        scale: outputWidth / geometry.displayBounds.width
                    )
                    drawingImage.draw(in: destination)
                }

                y += pageHeight + pageGap
            }
        }

        guard let data = image.pngData() else {
            throw RenderError.encodingFailed
        }
        return data
    }
}
