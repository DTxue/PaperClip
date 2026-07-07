import SwiftUI

// MARK: - 考试入口与选页

struct ExamStartOverlay: View {
    let latestAttempt: ExamAttemptHistoryRowData?
    let attemptCount: Int
    let onStart: () -> Void
    let onHistory: () -> Void
    let onContinue: (UUID) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 34))
                    .foregroundStyle(.secondary)

                Text("请选择页面后开始答题")
                    .font(.headline)

                Text("源 PDF 仅作为选页来源。书写、框选、导出和交卷都只作用于本次考试记录。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    onStart()
                } label: {
                    Label("开始答题", systemImage: "play.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if let latestAttempt {
                    Button {
                        onContinue(latestAttempt.id)
                    } label: {
                        Label("继续最近考试", systemImage: "arrow.uturn.forward.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                if attemptCount > 0 {
                    Button {
                        onHistory()
                    } label: {
                        Label("考试记录", systemImage: "clock.arrow.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Button {
                    onDismiss()
                } label: {
                    Label("退出", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(24)
            .frame(maxWidth: 420)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .accessibilityElement(children: .contain)
    }
}

struct PDFExamExitButton: View {
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            Label("退出考试", systemImage: "xmark.circle")
                .font(.headline)
                .frame(minWidth: 112, minHeight: 44)
                .padding(.horizontal, 4)
        }
        .buttonStyle(.bordered)
        .background(.regularMaterial, in: Capsule())
        .contentShape(Capsule())
        .disabled(isDisabled)
        .accessibilityLabel("退出考试")
    }
}
