import SwiftUI

struct AIRecognitionSummaryView: View {
    let recognition: AIQuestionRecognition

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(recognition.subject, systemImage: "book.closed")
                Spacer()
                Label(recognition.questionType, systemImage: "square.grid.2x2")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if !recognition.knowledgePoints.isEmpty {
                KnowledgeTagLayout(spacing: 8) {
                    ForEach(recognition.knowledgePoints.indices, id: \.self) { index in
                        KnowledgeTag(
                            title: recognition.knowledgePoints[index],
                            color: KnowledgeTag.palette[index % KnowledgeTag.palette.count]
                        )
                    }
                }
            }
        }
    }
}

struct AIModelSelectionButton: View {
    let model: AIAnswerModel
    let phase: AIAnalysisView.Phase
    let selectedModel: AIAnswerModel
    let isEnabled: Bool
    let action: () -> Void

    private var isSolvingThis: Bool {
        phase == .solving && selectedModel == model
    }

    private var isSelected: Bool {
        selectedModel == model && (phase == .solving || phase == .result)
    }

    private var canTap: Bool {
        isEnabled && phase != .solving
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: model.systemImage)
                    .font(.title3)
                    .foregroundStyle(model == .doubao ? .blue : .purple)
                    .frame(width: 34, height: 34)
                    .background(
                        (model == .doubao ? Color.blue : Color.purple).opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 9)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(model.title)
                        .font(.headline)
                    Text(isEnabled ? model.summary : "需要先在设置中配置推理接入点")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                trailingStatus
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!canTap)
        .opacity(isEnabled && !isSolvingThis && phase == .solving ? 0.4 : isEnabled ? 1 : 0.55)
        .accessibilityHint(isEnabled ? "使用该模型解析题目" : "需要先在设置中配置推理接入点")
    }

    @ViewBuilder
    private var trailingStatus: some View {
        if isSolvingThis {
            ProgressView().controlSize(.small)
        } else if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.accentColor)
        } else {
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
    }
}
