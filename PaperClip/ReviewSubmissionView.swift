import SwiftUI
import PDFKit

struct ReviewSubmissionView: View {
    let documentTitle: String
    let pdfURL: URL
    let drawings: [Int: Data]

    @Environment(\.dismiss) private var dismiss

    @State var selectedPages: Set<Int>
    @State var pageCount: Int?
    @State var answeredPageSet: Set<Int>
    @State var generatedImage: ShareImageRequest?
    @State var isGenerating = false
    @State var generationTaskSlot = ViewTaskSlot()
    @State var alert: AppAlert?

    init(documentTitle: String, pdfURL: URL, drawings: [Int: Data]) {
        self.documentTitle = documentTitle
        self.pdfURL = pdfURL
        self.drawings = drawings
        _selectedPages = State(initialValue: [])
        _pageCount = State(initialValue: nil)
        _answeredPageSet = State(initialValue: [])
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
                        ShareImageLink(request: generatedImage, previewTitle: "\(documentTitle) · 批阅") {
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
        .task(id: pdfURL) {
            await loadPageSelection()
        }
        .onDisappear {
            cancelGeneration()
        }
    }

    @ViewBuilder
    private var pageSelection: some View {
        if let pageCount {
            ReviewPageSelectionView(
                pageCount: pageCount,
                selectedPages: $selectedPages,
                answeredPageSet: answeredPageSet
            )
        } else {
            ProgressView("加载 PDF...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
