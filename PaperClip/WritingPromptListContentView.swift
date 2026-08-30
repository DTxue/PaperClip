import SwiftUI

struct WritingPromptListContentView: View {
    let language: WritingLanguage
    let snapshot: WritingHomeSnapshot
    let onDelete: (IndexSet, [WritingPromptRowData]) -> Void
    let onCreate: () -> Void

    var body: some View {
        if snapshot.visiblePrompts.isEmpty {
            ContentUnavailableView {
                Label("还没有\(language.shortTitle)写作题", systemImage: language.systemImage)
            } description: {
                Text("输入写作要求，生成一份适合当前年级的题目。")
            } actions: {
                Button("生成写作题", systemImage: "plus", action: onCreate)
                    .buttonStyle(.borderedProminent)
            }
            .listRowBackground(Color.clear)
        } else {
            Section("写作题") {
                ForEach(snapshot.visiblePrompts) { prompt in
                    NavigationLink {
                        WritingWorkspaceLoader(promptID: prompt.id)
                    } label: {
                        WritingPromptRow(
                            prompt: prompt,
                            draft: snapshot.latestDraftByPromptID[prompt.id],
                            review: snapshot.latestReviewByPromptID[prompt.id]
                        )
                    }
                }
                .onDelete { onDelete($0, snapshot.visiblePrompts) }
            }
        }
    }
}
