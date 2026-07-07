import SwiftUI

struct QuestionCropInstructionBanner: View {
    var body: some View {
        Text("拖动边角调整范围，拖动中心移动位置")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.black.opacity(0.5), in: Capsule())
            .padding(.top, 60)
    }
}

struct QuestionCropBottomBar: View {
    let canClear: Bool
    let onCancel: () -> Void
    let onClear: () -> Void
    let onReset: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button("取消", action: onCancel)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.white)

            Spacer()

            if canClear {
                Button("清除框选", action: onClear)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(.white)
            }

            Button("重置", action: onReset)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.white)

            Button("确认框选", action: onConfirm)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial)
    }
}
