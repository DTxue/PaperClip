import SwiftUI

// MARK: - 考试入口与选页

struct ExamStartOverlay: View {
    let latestAttempt: ExamAttemptHistoryRowData?
    let currentAttempt: ExamAttemptHistoryRowData?
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

                Text(currentAttempt == nil ? "整份 PDF 考试" : "继续未完成的考试")
                    .font(.headline)

                Text("每页独立提交和批阅；上一页批阅完成后继续下一页，全部页面批阅完成后才能开始下一轮。源 PDF 不会被修改。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    onStart()
                } label: {
                    Label(
                        currentAttempt == nil ? "开始整份 PDF" : "继续考试",
                        systemImage: currentAttempt == nil ? "doc.badge.plus" : "arrow.uturn.forward.circle"
                    )
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if currentAttempt == nil, let latestAttempt {
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

struct PDFExamSubmitButton: View {
    let actionState: PDFExamGradingActionState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(actionState.title, systemImage: actionState.systemImage)
                .font(.headline)
                .frame(minHeight: 44)
                .padding(.horizontal, 4)
        }
        .buttonStyle(.borderedProminent)
        .background(.regularMaterial, in: Capsule())
        .contentShape(Capsule())
        .disabled(!actionState.isEnabled)
        .accessibilityLabel(actionState.title)
    }
}

struct PDFExamTimerBadge: View {
    let startedAt: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Label(
                VocabularyStudySessionFormat.clockDuration(context.date.timeIntervalSince(startedAt)),
                systemImage: "timer"
            )
            .font(.subheadline.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.regularMaterial, in: Capsule())
            .accessibilityLabel("考试计时")
            .accessibilityValue(VocabularyStudySessionFormat.clockDuration(context.date.timeIntervalSince(startedAt)))
        }
    }
}

struct PDFExamPageProgressBadge: View {
    let progress: PDFExamPageProgress

    var body: some View {
        Label(
            "已交 \(progress.submittedPageIndices.count)/\(progress.pageIndices.count) · 已批 \(progress.gradedPageIndices.count)",
            systemImage: "doc.text.magnifyingglass"
        )
        .font(.subheadline.weight(.semibold))
        .monospacedDigit()
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: Capsule())
        .accessibilityLabel("考试进度")
        .accessibilityValue(
            "已提交 \(progress.submittedPageIndices.count) 页，共 \(progress.pageIndices.count) 页，已批阅 \(progress.gradedPageIndices.count) 页"
        )
    }
}
