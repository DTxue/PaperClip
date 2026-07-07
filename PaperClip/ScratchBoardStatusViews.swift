import SwiftUI

struct ScratchBoardConstructionStatus: View {
    let currentTool: GeoDrawingTool
    let interactionState: GeoInteractionState
    let cancel: () -> Void

    var body: some View {
        let stagedCount = interactionState.stagedPositions.count
        if stagedCount > 0 && currentTool != .pointer {
            ScratchBoardStatusPill {
                Label(constructionHint(staged: stagedCount), systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider().frame(height: 14)

                Button(action: cancel) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
                .accessibilityLabel("取消当前图形")
            }
        }
    }

    private func constructionHint(staged: Int) -> String {
        switch currentTool {
        case .segment: return "点击第 2 个点完成线段"
        case .circle: return "点击第 2 个点确定半径"
        case .arrow: return "点击第 2 个点完成箭头"
        case .triangle:
            return staged == 1 ? "已放置 1/3 个顶点" : "已放置 2/3 个顶点，点击第 3 个"
        case .rightAngle:
            return staged == 1 ? "点击直角顶点" : "点击第 2 条边的端点"
        case .angleMark:
            return staged == 1 ? "点击角的顶点" : "点击第 2 条边的端点"
        case .editLabel: return "点击已有字母进行替换"
        default: return ""
        }
    }
}

struct ScratchBoardSelectionStatus: View {
    let currentTool: GeoDrawingTool
    let selectedIDs: Set<UUID>
    let canvas: GeoCanvas
    let deleteSelected: () -> Void

    var body: some View {
        if currentTool == .pointer && !selectedIDs.isEmpty {
            let selectedPoint = canvas.points.first { selectedIDs.contains($0.id) }
            let selectedShape = canvas.shapes.first { selectedIDs.contains($0.id) }

            ScratchBoardStatusPill {
                if let point = selectedPoint {
                    Image(systemName: "circle.fill").font(.caption).foregroundStyle(.orange)
                    Text(point.label.isEmpty ? "控制点·拖动可移动" : "点 \(point.label)·拖动可移动")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if selectedShape != nil {
                    Image(systemName: "checkmark.circle").font(.caption).foregroundStyle(.blue)
                    Text("已选中图形·拖动可移动").font(.caption).foregroundStyle(.secondary)
                }

                Divider().frame(height: 14)

                Button(role: .destructive, action: deleteSelected) {
                    Image(systemName: "trash")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
                .accessibilityLabel("删除选中元素")
            }
        }
    }
}

private struct ScratchBoardStatusPill<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 8, content: content)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
    }
}
