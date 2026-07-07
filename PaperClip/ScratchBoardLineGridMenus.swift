import SwiftUI

extension ScratchLineWidthMenu {
    private var lineWidthOptions: [CGFloat] { [1, 1.5, 2, 3, 4] }

    var body: some View {
        Menu {
            ForEach(lineWidthOptions, id: \.self) { width in
                Button {
                    lineWidth = width
                } label: {
                    HStack {
                        Text("\(width, specifier: "%.1f") pt")
                        if lineWidth == width { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "lineweight")
                Text("\(lineWidth, specifier: "%.0f")pt").font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .accessibilityLabel("线条粗细")
    }
}

struct ScratchGridMenu: View {
    @Binding var gridStyle: ScratchGridStyle
    @Binding var viewportOrigin: CGPoint

    var body: some View {
        Menu {
            ForEach(ScratchGridStyle.allCases.filter { $0 != .none }, id: \.self) { style in
                Button {
                    gridStyle = style
                } label: {
                    HStack {
                        Text(style.rawValue)
                        if gridStyle == style { Image(systemName: "checkmark") }
                    }
                }
            }

            Divider()

            Button {
                viewportOrigin = .zero
            } label: {
                Label("画布归位", systemImage: "scope")
            }
            .disabled(viewportOrigin == .zero)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: gridStyle == .none ? "grid" : "grid.circle.fill")
                    .foregroundStyle(gridStyle != .none ? .blue : .secondary)
                Text("网格").font(.system(size: 9))
                    .foregroundStyle(gridStyle != .none ? .blue : .secondary)
            }
            .frame(minWidth: 38)
        }
        .accessibilityLabel("网格样式")
    }
}
