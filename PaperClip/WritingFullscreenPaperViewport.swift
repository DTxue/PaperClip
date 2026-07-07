import SwiftUI

struct WritingFullscreenPaperScrollView: View {
    let drawingStore: WritingDrawingStore
    @Binding var paperWidth: Double
    let paperSize: CGSize
    let paperStyle: WritingPaperStyle
    let blackPaperMode: Bool
    let rulingSpacing: Double
    let reloadToken: Int
    let onDrawingChanged: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView([.vertical, .horizontal]) {
                WritingPaperCanvasView(
                    drawingStore: drawingStore,
                    paperSize: paperSize,
                    paperStyle: paperStyle,
                    blackPaperMode: blackPaperMode,
                    rulingSpacing: rulingSpacing,
                    reloadToken: reloadToken,
                    onDrawingChanged: onDrawingChanged
                )
                .padding()
                .frame(minWidth: proxy.size.width, minHeight: proxy.size.height, alignment: .top)
                .onAppear {
                    expandPaperToVisibleWidth(proxy.size.width)
                }
                .onChange(of: proxy.size.width) { _, newWidth in
                    expandPaperToVisibleWidth(newWidth)
                }
            }
            .background(blackPaperMode ? Color.black : Color(uiColor: .systemGroupedBackground))
        }
    }

    private func expandPaperToVisibleWidth(_ visibleWidth: CGFloat) {
        guard let expandedWidth = WritingFullscreenPaperViewport.expandedPaperWidth(
            currentWidth: paperWidth,
            visibleWidth: visibleWidth
        ) else { return }
        paperWidth = expandedWidth
        onDrawingChanged()
    }
}
