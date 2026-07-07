import SwiftUI

enum PDFPageExportDestination {
    case share
    case photoLibrary
}

struct PDFPageExportToolbarContent: ToolbarContent {
    let snapshot: PDFPageExportSelectionSnapshot
    let generatedImage: ShareImageRequest?
    let onCancel: () -> Void
    let onResetSelection: () -> Void
    let onToggleAll: () -> Void
    let onStartExport: (PDFPageExportDestination) -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if generatedImage == nil {
                Button("取消", action: onCancel)
            } else {
                Button("重新选择", action: onResetSelection)
            }
        }

        ToolbarItem(placement: .primaryAction) {
            if let generatedImage {
                ShareImageLink(request: generatedImage, previewTitle: "PaperClip 页面长图") {
                    Label("分享", systemImage: "square.and.arrow.up")
                }
            } else {
                Button(snapshot.allSelected ? "取消全选" : "全选", action: onToggleAll)
                    .disabled(!snapshot.canToggleAll)
            }
        }

        ToolbarItemGroup(placement: .bottomBar) {
            if generatedImage == nil {
                Button {
                    onStartExport(.share)
                } label: {
                    Label("生成长图", systemImage: "photo.on.rectangle.angled")
                }
                .disabled(!snapshot.canExport)

                Spacer()

                Button {
                    onStartExport(.photoLibrary)
                } label: {
                    Label("保存到相册", systemImage: "photo.badge.plus")
                }
                .disabled(!snapshot.canExport)
            }
        }
    }
}
