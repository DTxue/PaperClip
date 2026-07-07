import SwiftUI

struct SelectionInstructionOverlay: View {
    let hasSelection: Bool

    var body: some View {
        VStack {
            Text(
                hasSelection
                    ? "拖动选框可移动范围，拖动圆点可调整边界"
                    : "在题目区域拖出矩形，松手后可继续调整范围"
            )
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: Capsule())
            .padding(.top, 12)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

struct ExamSubmittingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.24).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text("正在交卷批阅...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("正在交卷批阅")
    }
}
