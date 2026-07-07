import SwiftUI

/// 筛选类侧边栏行。使用系统 `Button`、SF Symbols 和 `listRowBackground`，
/// 对应 AGENTS.md 中“筛选类侧边栏”的统一选中样式。
struct SidebarFilterRow: View {
    let label: String
    var systemImage: String? = nil
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(isActive ? Color.accentColor : .secondary)
                        .frame(width: 20)
                }
                Text(label)
                    .foregroundStyle(isActive ? Color.accentColor : .primary)
                    .fontWeight(isActive ? .semibold : .regular)
                Spacer()
                if isActive {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .listRowBackground(isActive ? Color.accentColor.opacity(0.12) : Color.clear)
    }
}
