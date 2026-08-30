import SwiftUI

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
