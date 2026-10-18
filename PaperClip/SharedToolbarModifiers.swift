import SwiftUI

extension View {
    /// 编辑类 sheet 的标准取消/保存工具栏。仍使用 SwiftUI 原生 `ToolbarItem`
    /// 和系统 `Button`，只集中重复的 placement 与禁用状态样板。
    func editSheetToolbar(
        cancelTitle: String = "取消",
        confirmTitle: String = "保存",
        isConfirmDisabled: Bool = false,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(cancelTitle, action: onCancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(confirmTitle, action: onConfirm)
                    .disabled(isConfirmDisabled)
            }
        }
    }

    /// 页面内编辑态的标准取消/保存工具栏。保存按钮仍使用系统 Button，
    /// 只统一 primaryAction placement 与 `.borderedProminent` 样式。
    func prominentSaveToolbar(
        cancelTitle: String = "取消",
        saveTitle: String = "保存",
        isSaveDisabled: Bool = false,
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) -> some View {
        self.toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(cancelTitle, action: onCancel)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(saveTitle, action: onSave)
                    .buttonStyle(.borderedProminent)
                    .disabled(isSaveDisabled)
            }
        }
    }

    /// 单一强调操作按钮的标准工具栏。继续使用系统 `Button` 与 `ToolbarItem`，
    /// 只集中 PaperClip 对主要操作的 `.borderedProminent` 样式。
    func prominentActionToolbar(
        _ title: String,
        placement: ToolbarItemPlacement = .primaryAction,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        self.toolbar {
            ToolbarItem(placement: placement) {
                Button(title, action: action)
                    .buttonStyle(.borderedProminent)
                    .disabled(isDisabled)
            }
        }
    }

    /// 只读结果/详情页的标准完成按钮。保留系统 Toolbar placement，
    /// 避免各页面重复声明同一颗关闭按钮。
    func doneToolbar(
        title: String = "完成",
        action: @escaping () -> Void
    ) -> some View {
        singleButtonToolbar(title, placement: .confirmationAction, action: action)
    }

    /// 编辑/选择类 sheet 的标准取消按钮，使用系统 cancellationAction 位置。
    func cancelToolbar(
        title: String = "取消",
        action: @escaping () -> Void
    ) -> some View {
        singleButtonToolbar(title, placement: .cancellationAction, action: action)
    }

    private func singleButtonToolbar(
        _ title: String,
        placement: ToolbarItemPlacement,
        action: @escaping () -> Void
    ) -> some View {
        self.toolbar {
            ToolbarItem(placement: placement) {
                Button(title, action: action)
            }
        }
    }
}
