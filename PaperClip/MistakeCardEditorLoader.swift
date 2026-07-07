import SwiftUI
import SwiftData

struct MistakeCardEditorLoader: View {
    @Environment(\.modelContext) private var modelContext
    let cardID: UUID

    @State private var card: MistakeCard?
    @State private var didLoad = false
    @State private var alert: AppAlert?

    var body: some View {
        Group {
            if let card {
                MistakeCardEditorView(card: card)
            } else if didLoad {
                ContentUnavailableView("错题不存在", systemImage: "rectangle.stack")
            } else {
                ProgressView("正在载入错题…")
            }
        }
        .task(id: cardID) {
            loadCard()
        }
        .appAlert($alert)
    }

    private func loadCard() {
        do {
            didLoad = false
            card = try modelContext.fetchMistakeCard(id: cardID)
            didLoad = true
        } catch {
            card = nil
            didLoad = true
            alert = AppAlert(title: "无法读取错题", error: error)
        }
    }
}
