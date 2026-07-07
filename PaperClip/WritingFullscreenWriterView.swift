import SwiftUI

struct WritingFullscreenWriterView: View {
    @Environment(\.dismiss) private var dismiss

    let prompt: WritingPrompt
    let drawingStore: WritingDrawingStore
    @Binding var paperStyle: WritingPaperStyle
    @Binding var blackPaperMode: Bool
    @Binding var paperWidth: Double
    @Binding var paperHeight: Double
    @Binding var rulingSpacing: Double
    let availablePaperStyles: [WritingPaperStyle]
    let reloadToken: Int
    let onDrawingChanged: () -> Void
    let onSave: () -> Void

    @State private var isShowingRequirement = false
    @State private var isShowingPaperSizing = false

    private var paperSize: CGSize {
        WritingPaperMetrics.clampedSize(width: paperWidth, height: paperHeight)
    }

    var body: some View {
        NavigationStack {
            WritingFullscreenPaperScrollView(
                drawingStore: drawingStore,
                paperWidth: $paperWidth,
                paperSize: paperSize,
                paperStyle: paperStyle,
                blackPaperMode: blackPaperMode,
                rulingSpacing: rulingSpacing,
                reloadToken: reloadToken,
                onDrawingChanged: onDrawingChanged
            )
            .navigationTitle(prompt.generatedTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        onSave()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    WritingFullscreenWriterSettingsMenu(
                        language: prompt.language,
                        availablePaperStyles: availablePaperStyles,
                        paperStyle: $paperStyle,
                        blackPaperMode: $blackPaperMode,
                        isShowingRequirement: $isShowingRequirement,
                        isShowingPaperSizing: $isShowingPaperSizing
                    )
                }
            }
            .sheet(isPresented: $isShowingRequirement) {
                WritingRequirementSheet(prompt: prompt, isPresented: $isShowingRequirement)
            }
            .sheet(isPresented: $isShowingPaperSizing) {
                WritingPaperSizingView(
                    paperStyle: paperStyle,
                    paperWidth: $paperWidth,
                    paperHeight: $paperHeight,
                    rulingSpacing: $rulingSpacing,
                    onReset: {
                        paperWidth = WritingPaperMetrics.defaultWidth
                        paperHeight = WritingPaperMetrics.defaultHeight
                        rulingSpacing = WritingPaperMetrics.defaultRulingSpacing(for: paperStyle)
                        onDrawingChanged()
                    }
                )
            }
        }
        .interactiveDismissDisabled()
        .onDisappear(perform: onSave)
    }
}
