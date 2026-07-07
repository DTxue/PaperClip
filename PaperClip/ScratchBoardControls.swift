import SwiftUI

struct ScratchBoardGeometryToolbar: View {
    @Binding var currentTool: GeoDrawingTool
    @Binding var shapeStyle: GeoStyle
    @Binding var isSnappingEnabled: Bool
    @Binding var snapToExistingPoints: Bool
    @Binding var snapToExistingLines: Bool
    @Binding var snapToGrid: Bool
    @Binding var bypassSnapOnce: Bool
    @Binding var gridStyle: ScratchGridStyle
    @Binding var viewportOrigin: CGPoint
    @Binding var selectedLetter: String

    let canUndo: Bool
    let canRedo: Bool
    let undo: () -> Void
    let redo: () -> Void
    let snapModeChanged: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(GeoDrawingTool.allCases) { tool in
                        ScratchGeometryToolButton(
                            tool: tool,
                            isSelected: currentTool == tool,
                            select: { currentTool = tool }
                        )
                    }

                    Divider().frame(height: 28)

                    ColorPicker("", selection: $shapeStyle.color, supportsOpacity: false)
                        .labelsHidden().frame(width: 32, height: 32)
                        .accessibilityLabel("图形颜色")

                    ScratchLineWidthMenu(lineWidth: $shapeStyle.lineWidth)
                    ScratchSnapMenu(
                        isSnappingEnabled: $isSnappingEnabled,
                        snapToExistingPoints: $snapToExistingPoints,
                        snapToExistingLines: $snapToExistingLines,
                        snapToGrid: $snapToGrid,
                        bypassSnapOnce: $bypassSnapOnce,
                        snapModeChanged: snapModeChanged
                    )
                    ScratchGridMenu(gridStyle: $gridStyle, viewportOrigin: $viewportOrigin)

                    Divider().frame(height: 28)

                    Button(action: undo) {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .foregroundStyle(canUndo ? .secondary : .tertiary)
                    .disabled(!canUndo)
                    .accessibilityLabel("撤销")

                    Button(action: redo) {
                        Image(systemName: "arrow.uturn.forward")
                    }
                    .foregroundStyle(canRedo ? .secondary : .tertiary)
                    .disabled(!canRedo)
                    .accessibilityLabel("重做")
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
            }
            .frame(height: 54)

            if currentTool == .editLabel {
                ScratchLetterPalette(selectedLetter: $selectedLetter)
            }
        }
        .background(.ultraThinMaterial)
    }
}
