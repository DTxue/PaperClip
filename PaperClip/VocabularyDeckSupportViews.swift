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
                    "无法打开学习集",
                    systemImage: "character.book.closed",
                    description: Text("这个学习集可能已被删除。")
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
            alert = AppAlert(title: "无法读取学习集", error: error)
        }
    }
}

enum VocabularyDeckSection: String, CaseIterable, Identifiable {
    case words
    case contextPractice
    case mastery
    case scores
    case settings

    var id: String { rawValue }

    static func sections(for kind: VocabularyDeckKind) -> [VocabularyDeckSection] {
        allCases.filter { section in
            kind.usesWordSpecificFeatures || section != .contextPractice
        }
    }

    func title(for kind: VocabularyDeckKind) -> String {
        switch self {
        case .words: kind.listTitle
        case .contextPractice: "语境练习"
        case .mastery: "熟练度"
        case .scores: "成绩"
        case .settings: "\(kind.collectionName)设置"
        }
    }

    var systemImage: String {
        switch self {
        case .words: "list.bullet"
        case .contextPractice: "text.bubble"
        case .mastery: "gauge.with.dots.needle.67percent"
        case .scores: "chart.line.uptrend.xyaxis"
        case .settings: "gearshape"
        }
    }
}
