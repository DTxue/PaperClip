import SwiftUI
import SwiftData

struct VocabularyDeckLoader: View {
    @Environment(\.modelContext) private var modelContext
    let deckID: UUID
    @State private var deck: VocabularyDeck?
    @State private var alert: AppAlert?

    var body: some View {
        Group {
            if let deck {
                VocabularyDeckView(deck: deck)
            } else {
                ContentUnavailableView(
                    "无法打开词集",
                    systemImage: "character.book.closed",
                    description: Text("这个词集可能已被删除。")
                )
            }
        }
        .appAlert($alert)
        .task(id: deckID) {
            loadDeck()
        }
    }

    private func loadDeck() {
        do {
            deck = try modelContext.fetchVocabularyDeck(id: deckID)
        } catch {
            deck = nil
            alert = AppAlert(title: "无法读取词集", error: error)
        }
    }
}

enum VocabularyDeckSection: String, CaseIterable, Identifiable {
    case words = "单词"
    case contextPractice = "语境练习"
    case article = "词生文"
    case mastery = "熟练度"
    case scores = "成绩"
    case settings = "词集设置"

    var id: String { rawValue }
    var systemImage: String {
        switch self {
        case .words: "list.bullet"
        case .contextPractice: "text.bubble"
        case .article: "text.book.closed"
        case .mastery: "gauge.with.dots.needle.67percent"
        case .scores: "chart.line.uptrend.xyaxis"
        case .settings: "gearshape"
        }
    }
}
