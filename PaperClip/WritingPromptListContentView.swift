import SwiftUI

struct WritingPromptListContentView: View {
    let language: WritingLanguage
    let snapshot: WritingHomeSnapshot
    let onDelete: (IndexSet, [WritingPromptRowData]) -> Void

    var body: some View {
        if snapshot.visiblePrompts.isEmpty {
            ContentUnavailableView(
                "还没有\(language.shortTitle)写作题",
                systemImage: language.systemImage,
                description: Text("点击右上角 +，输入写作要求生成题目。")
            )
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
