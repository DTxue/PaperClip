import SwiftUI

struct ScratchBoardTitleBar<MoveGesture: Gesture>: View {
    @Binding var showOpacitySlider: Bool
    @Binding var backgroundOpacity: Double
    @Binding var isGeometricMode: Bool

    let moveGesture: MoveGesture
    let clearHandwriting: () -> Void
    let clearGeometry: () -> Void
    let clearAll: () -> Void
    let close: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "scribble.variable").foregroundStyle(.blue)
                Text("草稿板").font(.headline)
                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { showOpacitySlider.toggle() }
                } label: {
                    Image(systemName: "circle.lefthalf.filled")
                }
                .foregroundStyle(showOpacitySlider ? .blue : .secondary)
                .accessibilityLabel("透明度调节")

                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { isGeometricMode.toggle() }
                } label: {
                    Image(systemName: isGeometricMode ? "triangle.circle.fill" : "triangle.circle")
                }
                .foregroundStyle(isGeometricMode ? Color.blue : Color.secondary)
                .accessibilityLabel("几何画图模式")

                Menu {
                    Button(role: .destructive, action: clearHandwriting) {
                        Label("清空手写", systemImage: "scribble")
                    }
                    Button(role: .destructive, action: clearGeometry) {
                        Label("清空几何图形", systemImage: "triangle")
                    }
                    Button(role: .destructive, action: clearAll) {
                        Label("全部清空", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "trash").foregroundStyle(.secondary)
                }
                .accessibilityLabel("清空草稿板")

                Button(action: close) { Image(systemName: "xmark") }
                    .accessibilityLabel("关闭草稿板")
            }
            .padding(.horizontal, 14)
            .frame(height: 50)

            if showOpacitySlider {
                HStack(spacing: 10) {
                    Image(systemName: "sun.min").foregroundStyle(.secondary).font(.caption)
                    Slider(value: $backgroundOpacity, in: 0.0...1.0, step: 0.01)
                    Image(systemName: "sun.max").foregroundStyle(.secondary).font(.caption)
                    Text("\(Int(backgroundOpacity * 100))%")
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
                .padding(.horizontal, 14).padding(.bottom, 8)
            }
        }
        .background(.regularMaterial)
        .contentShape(Rectangle())
        .gesture(moveGesture)
    }
}
