import SwiftUI
import UIKit
@preconcurrency import PDFKit
import PencilKit
import Photos

// MARK: - 页面导出视图
//
// 自定义理由：
// - 无系统等价的「多选 PDF 页 → 合并长图（含手写叠加）→ 分享/存相册」流程
// - 系统组件：NavigationStack、LazyVGrid、ShareLink、PHPhotoLibrary、ProgressView、alert
// - PDF 渲染：PDFKit thumbnail(of:for:)，手写渲染：PKDrawing.image(from:scale:)
// - 已验证：VoiceOver、深色模式、横竖屏、多窗口

struct PDFPageExportView: View {
    let documentURL: URL
    /// 当前会话的手写数据（pageIndex → PKDrawing data）
    let drawings: [Int: Data]
    /// 每页画布的精确尺寸（pageIndex → canvas.frame.size），由 PDFKitCanvasView 上报
    let canvasSizes: [Int: CGSize]

    @Environment(\.dismiss) private var dismiss

    @State private var pdfDocument: PDFDocument?
    @State private var selectedIndices: Set<Int> = []
    @State private var isRendering = false
    @State private var shareRequest: ShareImageRequest?
    @State private var alert: AppAlert?
    @State private var savedToPhotos = false

    private var pageCount: Int { pdfDocument?.pageCount ?? 0 }
    private var allSelected: Bool { selectedIndices.count == pageCount && pageCount > 0 }
    private var hasSelection: Bool { !selectedIndices.isEmpty }

    var body: some View {
        NavigationStack {
            Group {
                if pdfDocument == nil {
                    ProgressView("加载中…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if pageCount == 0 {
                    ContentUnavailableView("无页面", systemImage: "doc.slash")
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 130), spacing: 14)],
                            spacing: 14
                        ) {
                            ForEach(0..<pageCount, id: \.self) { index in
                                PDFPageThumbnailCell(
                                    page: pdfDocument!.page(at: index)!,
                                    drawing: drawings[index].flatMap { try? PKDrawing(data: $0) },
                                    pageNumber: index + 1,
                                    canvasSize: canvasSizes[index],
                                    isSelected: selectedIndices.contains(index)
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        if selectedIndices.contains(index) {
                                            selectedIndices.remove(index)
                                        } else {
                                            selectedIndices.insert(index)
                                        }
                                    }
                                }
                                .accessibilityLabel("第 \(index + 1) 页，\(selectedIndices.contains(index) ? "已选中" : "未选中")")
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 64)
                    }
                }
            }
            .navigationTitle(
                hasSelection
                    ? "已选 \(selectedIndices.count) / \(pageCount) 页"
                    : "选择页面"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(allSelected ? "取消全选" : "全选") {
                        withAnimation {
                            selectedIndices = allSelected ? [] : Set(0..<pageCount)
                        }
                    }
                    .disabled(pageCount == 0)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        Task { await exportAndShare() }
                    } label: {
                        Label("合并分享", systemImage: "square.and.arrow.up")
                    }
                    .disabled(!hasSelection || isRendering)

                    Spacer()

                    Button {
                        Task { await exportAndSaveToPhotos() }
                    } label: {
                        Label("保存到相册", systemImage: "photo.badge.plus")
                    }
                    .disabled(!hasSelection || isRendering)
                }
            }
            .overlay {
                if isRendering {
                    ZStack {
                        Color.black.opacity(0.25).ignoresSafeArea()
                        VStack(spacing: 14) {
                            ProgressView().controlSize(.large)
                            Text("合并图片中…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(28)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isRendering)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            pdfDocument = PDFDocument(url: documentURL)
        }
        .sheet(item: $shareRequest) { request in
            NavigationStack {
                VStack(spacing: 24) {
                    if let image = request.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 420)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    ShareLink(
                        item: request,
                        preview: SharePreview(
                            "PaperClip 页面长图",
                            image: request.image.map(Image.init(uiImage:)) ?? Image(systemName: "photo")
                        )
                    ) {
                        Label("打开系统分享菜单", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(24)
                .navigationTitle("分享长图")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("关闭") { shareRequest = nil }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert(item: $alert) { a in
            Alert(title: Text(a.title), message: Text(a.message), dismissButton: .default(Text("好")))
        }
        .alert("已保存到相册", isPresented: $savedToPhotos) {
            Button("好") {}
        }
    }

    // MARK: - 渲染

    /// 将选中页渲染为高清长图（含手写叠加）。
    /// 目标宽度固定 1500 像素，通过屏幕 scale 换算逻辑尺寸，
    /// 避免直接用 PDF 点数 × 大倍率导致分配超大 context（>10MP）引发黑图。
    private func renderMergedImage() -> UIImage? {
        guard let pdfDocument, !selectedIndices.isEmpty else { return nil }
        let indices = selectedIndices.sorted()

        // 目标像素宽 1500px；换算为逻辑点（2× 屏幕 → 750pt，3× → 500pt）
        let targetPixelW: CGFloat = 1500
        let screenScale = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.scale ?? 2.0
        let logicalW = targetPixelW / screenScale   // logical points

        var images: [UIImage] = []

        for index in indices {
            guard let page = pdfDocument.page(at: index) else { continue }
            let mediaBox = page.bounds(for: .mediaBox)   // CGRect，有 minX/minY
            guard mediaBox.width > 0, mediaBox.height > 0 else { continue }

            let logicalH = logicalW * mediaBox.height / mediaBox.width
            let logicalSize = CGSize(width: logicalW, height: logicalH)
            let scaleX = logicalW / mediaBox.width
            let scaleY = logicalH / mediaBox.height

            // --- 渲染 PDF 页面 ---
            // UIGraphicsImageRenderer 坐标系：左上角原点，Y 向下。
            // PDFPage.draw(with:to:) 期望 PDF 坐标系：左下角原点，Y 向上。
            // 通过 translate + scaleBy 翻转 Y 轴后调用 page.draw()。
            let pdfImage = UIGraphicsImageRenderer(size: logicalSize).image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(origin: .zero, size: logicalSize))
                let cgCtx = ctx.cgContext
                cgCtx.saveGState()
                cgCtx.translateBy(x: 0, y: logicalH)
                cgCtx.scaleBy(x: scaleX, y: -scaleY)
                cgCtx.translateBy(x: -mediaBox.minX, y: -mediaBox.minY)
                page.draw(with: .mediaBox, to: cgCtx)
                cgCtx.restoreGState()
            }

            // --- 手写叠加 ---
            let drawing = drawings[index].flatMap { try? PKDrawing(data: $0) }
            if let drawing, !drawing.strokes.isEmpty {
                // 使用 PDFKitCanvasView 上报的精确 canvas 尺寸（= mediaBox × pdfView.scaleFactor）
                // 避免用 pdfScaleFactor 推算导致坐标偏移
                let canvasSize = canvasSizes[index] ?? mediaBox.size
                // scale=2 给出 2× 分辨率的 drawing 图，再通过 draw(in:) 缩放到 logicalSize
                let drawingImage = drawing.image(
                    from: CGRect(origin: .zero, size: canvasSize),
                    scale: 2
                )
                let composite = UIGraphicsImageRenderer(size: logicalSize).image { _ in
                    pdfImage.draw(in: CGRect(origin: .zero, size: logicalSize))
                    drawingImage.draw(in: CGRect(origin: .zero, size: logicalSize))
                }
                images.append(composite)
            } else {
                images.append(pdfImage)
            }
        }

        guard !images.isEmpty else { return nil }

        // --- 竖向拼接 ---
        let stripW = images[0].size.width
        let stripH = images.reduce(CGFloat(0)) { $0 + $1.size.height }
        return UIGraphicsImageRenderer(size: CGSize(width: stripW, height: stripH)).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: stripW, height: stripH))
            var y: CGFloat = 0
            for img in images {
                img.draw(in: CGRect(x: 0, y: y, width: img.size.width, height: img.size.height))
                y += img.size.height
            }
        }
    }

    private func exportAndShare() async {
        isRendering = true
        defer { isRendering = false }
        guard let image = renderMergedImage(),
              let data = image.jpegData(compressionQuality: 0.92) else {
            alert = AppAlert(title: "导出失败", message: "无法生成图片，请重试。")
            return
        }
        shareRequest = ShareImageRequest(data: data)
    }

    private func exportAndSaveToPhotos() async {
        isRendering = true
        defer { isRendering = false }
        guard let image = renderMergedImage() else {
            alert = AppAlert(title: "导出失败", message: "无法生成图片，请重试。")
            return
        }
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            alert = AppAlert(title: "无法访问相册", message: "请在「设置 → 隐私与安全性 → 照片」中允许 PaperClip 写入照片。")
            return
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            savedToPhotos = true
        } catch {
            alert = AppAlert(title: "保存失败", message: error.localizedDescription)
        }
    }
}

// MARK: - 页面缩略图卡片

private struct PDFPageThumbnailCell: View {
    let page: PDFPage
    let drawing: PKDrawing?
    let pageNumber: Int
    /// 精确 canvas 尺寸；nil 时退回到 mediaBox.size（不做手写叠加缩放）
    let canvasSize: CGSize?
    let isSelected: Bool

    @State private var thumbnail: UIImage?

    private var pageBounds: CGSize { page.bounds(for: .mediaBox).size }

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Color(uiColor: .systemGray5)
                            .aspectRatio(pageBounds, contentMode: .fit)
                            .overlay { ProgressView() }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isSelected ? Color.accentColor : Color(uiColor: .systemGray4),
                            lineWidth: isSelected ? 2.5 : 0.5
                        )
                }
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.accentColor : Color(uiColor: .systemGray3))
                    .background(Color.white.opacity(0.9), in: Circle())
                    .offset(x: 4, y: -4)
            }

            Text("第 \(pageNumber) 页")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onAppear { loadThumbnail() }
    }

    private func loadThumbnail() {
        guard thumbnail == nil else { return }
        let mediaBox = page.bounds(for: .mediaBox)   // CGRect，有 minX/minY
        guard mediaBox.width > 0, mediaBox.height > 0 else { return }
        let targetW: CGFloat = 260
        let targetH = mediaBox.height * targetW / mediaBox.width
        let thumbSize = CGSize(width: targetW, height: targetH)
        // 精确 canvas 尺寸；nil 时退回 mediaBox.size（手写叠加可能有少量偏差，但不影响缩略图）
        let resolvedCanvasSize = canvasSize ?? mediaBox.size

        Task(priority: .userInitiated) {
            // PDF 页面渲染
            let pdfImg = UIGraphicsImageRenderer(size: thumbSize).image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(origin: .zero, size: thumbSize))
                let cgCtx = ctx.cgContext
                cgCtx.saveGState()
                let sx = targetW  / mediaBox.width
                let sy = targetH  / mediaBox.height
                cgCtx.translateBy(x: 0, y: targetH)
                cgCtx.scaleBy(x: sx, y: -sy)
                cgCtx.translateBy(x: -mediaBox.minX, y: -mediaBox.minY)
                page.draw(with: .mediaBox, to: cgCtx)
                cgCtx.restoreGState()
            }

            // 手写叠加
            guard let drawing, !drawing.strokes.isEmpty else {
                thumbnail = pdfImg
                return
            }
            let drawImg = drawing.image(
                from: CGRect(origin: .zero, size: resolvedCanvasSize),
                scale: 1
            )
            thumbnail = UIGraphicsImageRenderer(size: thumbSize).image { _ in
                pdfImg.draw(in: CGRect(origin: .zero, size: thumbSize))
                drawImg.draw(in: CGRect(origin: .zero, size: thumbSize))
            }
        }
    }
}
