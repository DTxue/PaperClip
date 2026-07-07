import SwiftUI

struct PDFExamPageSelectionToolbarContent: ToolbarContent {
    let snapshot: PDFPageExportSelectionSnapshot
    @Binding var selectedIndices: Set<Int>
    @Binding var alert: AppAlert?
    let onCancel: () -> Void
    let onStart: ([Int]) -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("取消", action: onCancel)
        }

        ToolbarItem(placement: .primaryAction) {
            Button(snapshot.allSelected ? "取消全选" : "全选") {
                withAnimation {
                    selectedIndices = PDFPageExportSelectionSupport.toggledAllSelection(
                        selectedIndices: selectedIndices,
                        pageCount: snapshot.pageCount
                    )
                }
            }
            .disabled(!snapshot.canToggleAll)
        }

        ToolbarItem(placement: .confirmationAction) {
            Button("开始") {
                let indices = selectedIndices.sorted()
                guard !indices.isEmpty else {
                    alert = AppAlert(title: "请选择页面", message: "至少选择一页后才能开始答题。")
                    return
                }
                onStart(indices)
            }
            .disabled(!snapshot.hasSelection)
        }
    }
}
