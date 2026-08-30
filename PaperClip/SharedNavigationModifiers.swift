import SwiftUI

struct PaperClipNavigationSplitView<Sidebar: View, Detail: View>: View {
    private let sidebar: Sidebar
    private let detail: Detail

    init(
        @ViewBuilder _ sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail
    ) {
        self.sidebar = sidebar()
        self.detail = detail()
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            sidebar
                .paperClipThemedSurface(.sidebar)
        } detail: {
            detail
                .paperClipThemedSurface(.page)
        }
        .paperClipSplitView()
    }
}

extension View {
    /// 全局侧边栏列规范。保留 SwiftUI 原生 `NavigationSplitView` / `List` 行为，
    /// 只集中仓库约定的标题、固定列宽和移除折叠按钮，避免各页面重复手写。
    func paperClipSidebarColumn(_ title: String) -> some View {
        self
            .paperClipThemedSurface(.sidebar)
            .navigationTitle(title)
            .navigationSplitViewColumnWidth(min: 180, ideal: 220)
            .toolbar(removing: .sidebarToggle)
    }

    /// 全局双栏布局规范。保留系统 `NavigationSplitView` 行为，
    /// 只集中 PaperClip 对 split view 的 balanced 样式约定。
    func paperClipSplitView() -> some View {
        self.navigationSplitViewStyle(.balanced)
    }

}
