import SwiftUI

struct ScratchGeometryToolButton: View {
    let tool: GeoDrawingTool
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(spacing: 2) {
                Image(systemName: tool.sfSymbol).font(.system(size: 15))
                Text(tool.displayName).font(.system(size: 9))
            }
            .frame(minWidth: 44)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color.blue.opacity(0.15) : Color.clear,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .foregroundStyle(isSelected ? .blue : .primary)
        .accessibilityLabel(tool.displayName)
    }
}

struct ScratchLineWidthMenu: View {
    @Binding var lineWidth: CGFloat
}
