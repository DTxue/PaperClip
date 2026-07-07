import SwiftUI

struct ScratchSnapMenu: View {
    @Binding var isSnappingEnabled: Bool
    @Binding var snapToExistingPoints: Bool
    @Binding var snapToExistingLines: Bool
    @Binding var snapToGrid: Bool
    @Binding var bypassSnapOnce: Bool

    let snapModeChanged: () -> Void

    var body: some View {
        Menu {
            Toggle("启用智能吸附", isOn: $isSnappingEnabled)

            Section("吸附目标") {
                Toggle("已有点", isOn: $snapToExistingPoints)
                Toggle("已有线条与圆周", isOn: $snapToExistingLines)
                Toggle("网格或点阵", isOn: $snapToGrid)
            }

            Divider()

            Button {
                bypassSnapOnce.toggle()
                snapModeChanged()
            } label: {
                Label(
                    bypassSnapOnce ? "取消下一点自由放置" : "下一点自由放置",
                    systemImage: bypassSnapOnce ? "checkmark.circle.fill" : "hand.tap"
                )
            }
            .disabled(!isSnappingEnabled)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "scope")
                Text(bypassSnapOnce ? "自由" : "吸附")
                    .font(.system(size: 9))
            }
            .frame(minWidth: 38)
            .foregroundStyle(bypassSnapOnce || !isSnappingEnabled ? Color.orange : Color.secondary)
        }
        .accessibilityLabel("吸附设置")
        .accessibilityValue(bypassSnapOnce ? "下一点自由放置" : isSnappingEnabled ? "已启用" : "已关闭")
    }
}
