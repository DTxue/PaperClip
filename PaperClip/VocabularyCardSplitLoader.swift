import SwiftData
import SwiftUI

struct VocabularyCardSplitLoader: View {
    @Environment(\.modelContext) private var modelContext
    let deck: VocabularyDeck
    let cardID: UUID
    @State private var card: VocabularyCard?
    @State private var alert: AppAlert?

    var body: some View {
        Group {
            if let card {
                VocabularyCardSplitView(deck: deck, card: card)
            } else {
                ContentUnavailableView(
                    "无法拆分单词",
                    systemImage: "scissors",
                    description: Text("这个单词可能已被删除。")
                )
            }
        }
        .appAlert($alert)
        .task(id: cardID) {
            loadCard()
        }
    }

    private func loadCard() {
        do {
            card = try modelContext.fetchVocabularyCard(id: cardID)
        } catch {
            card = nil
            alert = AppAlert(title: "无法读取单词", error: error)
        }
    }
}
