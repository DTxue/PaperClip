import SwiftUI

extension DiaryAIResultView {
    @ViewBuilder
    func aiSection(
        icon: String, color: Color,
        title: String,
        original: String,
        aiResult: Binding<String>,
        state: Binding<SectionAIState>,
        retryAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 4) {
                Text("原始记录")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text(original)
                    .font(.body)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))

            aiResultStateView(
                aiResult: aiResult,
                state: state,
                retryAction: retryAction
            )
        }
    }

    @ViewBuilder
    func aiResultStateView(
        aiResult: Binding<String>,
        state: Binding<SectionAIState>,
        retryAction: @escaping () -> Void
    ) -> some View {
        DiaryAIResultStateView(
            aiResult: aiResult,
            state: state,
            retryAction: retryAction
        )
    }

    var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("今天有什么值得记录的", systemImage: "note.text")
                .font(.headline)
                .foregroundStyle(.purple)
            Text(entry.noted)
                .font(.body)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
        }
    }
}
