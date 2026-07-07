import SwiftUI
import SwiftData

struct WritingWorkspaceLoader: View {
    @Environment(\.modelContext) private var modelContext
    let promptID: UUID
    @State private var prompt: WritingPrompt?
    @State private var alert: AppAlert?

    var body: some View {
        Group {
            if let prompt {
                WritingWorkspaceView(prompt: prompt)
            } else {
                ContentUnavailableView(
                    "无法打开写作题",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("这道写作题可能已被删除。")
                )
            }
        }
        .appAlert($alert)
        .task(id: promptID) {
            loadPrompt()
        }
    }

    private func loadPrompt() {
        do {
            prompt = try modelContext.fetchWritingPrompt(id: promptID)
        } catch {
            prompt = nil
            alert = AppAlert(title: "无法读取写作题", error: error)
        }
    }
}
