import SwiftUI
@preconcurrency import PDFKit

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
    @Environment(\.displayScale) var displayScale

    @State var pageCount: Int?
    @State var selectedIndices: Set<Int> = []
    @State var isRendering = false
    @State var exportTaskSlot = ViewTaskSlot()
    @State var generatedImage: ShareImageRequest?
    @State var alert: AppAlert?

    private var selectionSnapshot: PDFPageExportSelectionSnapshot {
        PDFPageExportSelectionSnapshot(
            pageCount: pageCount,
            selectedIndices: selectedIndices,
            isRendering: isRendering
        )
    }

    var body: some View {
        let snapshot = selectionSnapshot

        NavigationStack {
            PDFPageExportContentView(
                pageCount: pageCount,
                generatedImage: generatedImage,
                selectedIndices: $selectedIndices
            )
            .navigationTitle(snapshot.navigationTitle(hasGeneratedImage: generatedImage != nil))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                PDFPageExportToolbarContent(
                    snapshot: snapshot,
                    generatedImage: generatedImage,
                    onCancel: { dismiss() },
                    onResetSelection: {
                        cancelExport()
                        generatedImage = nil
                    },
                    onToggleAll: {
                        withAnimation {
                            selectedIndices = PDFPageExportSelectionSupport.toggledAllSelection(
                                selectedIndices: selectedIndices,
                                pageCount: snapshot.pageCount
                            )
                        }
                    },
                    onStartExport: { destination in
                        startExport(destination)
                    }
                )
            }
            .overlay {
                if isRendering {
                    PDFPageExportProgressOverlay()
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isRendering)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task(id: documentURL) {
            await loadPageCount()
        }
        .onDisappear {
            cancelExport()
        }
        .appAlert($alert)
    }
}
