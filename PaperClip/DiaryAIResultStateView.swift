import SwiftUI

struct DiaryAIResultStateView: View {
    @Binding var aiResult: String
    @Binding var state: SectionAIState
    let retryAction: () -> Void

    var body: some View {
        switch state {
        case .loading:
            loadingView
        case .done:
            doneView
        case .failed(let message):
            failedView(message)
        case .ignored:
            ignoredView
        }
    }

    private var loadingView: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("AI 整理中…")
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    private var doneView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("AI 整理")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button {
                    aiResult = ""
                    state = .ignored
                } label: {
                    Label("忽略", systemImage: "xmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            TextEditor(text: $aiResult)
                .frame(minHeight: 100)
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        .overlay { RoundedRectangle(cornerRadius: 10).stroke(Color.accentColor.opacity(0.2)) }
    }

    private func failedView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("AI 整理失败", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Spacer()
                Button(action: retryAction) {
                    Label("重试", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
            Text(message)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .background(.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    private var ignoredView: some View {
        HStack {
            Text("AI 整理：已忽略")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
            Button(action: retryAction) {
                Label("重新整理", systemImage: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
        .padding(12)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
    }
}
