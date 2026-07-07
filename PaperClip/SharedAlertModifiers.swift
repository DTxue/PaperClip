import SwiftUI

extension View {
    /// 统一的错误/提示弹窗。集中处理 `AppAlert`，消除各视图重复的 `Alert(...)` 样板。
    /// 内部仍使用系统 `alert(item:)`，不引入任何自定义弹窗实现。
    func appAlert(_ alert: Binding<AppAlert?>) -> some View {
        self.alert(item: alert) { value in
            Alert(
                title: Text(value.title),
                message: Text(value.message),
                dismissButton: .default(Text("好"))
            )
        }
    }

    /// 统一的删除确认弹窗。内部仍使用 SwiftUI 原生 `confirmationDialog`，
    /// 调用方只描述业务文案和删除动作，避免重复手写清空待删除 item 的样板。
    func deleteConfirmationDialog<Item: Sendable>(
        item: Binding<Item?>,
        title: @escaping (Item) -> String,
        message: ((Item) -> String)? = nil,
        confirmTitle: String = "删除",
        onDelete: @escaping (Item) -> Void
    ) -> some View {
        confirmationDialog(
            item.wrappedValue.map(title) ?? "",
            isPresented: Binding(isPresenting: item),
            titleVisibility: .visible
        ) {
            Button(confirmTitle, role: .destructive) {
                if let value = item.wrappedValue {
                    onDelete(value)
                }
                item.wrappedValue = nil
            }
            Button("取消", role: .cancel) {
                item.wrappedValue = nil
            }
        } message: {
            if let value = item.wrappedValue,
               let message {
                Text(message(value))
            }
        }
    }
}
