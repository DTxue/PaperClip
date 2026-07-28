import SwiftUI
import SwiftData

struct VocabularyDeckView: View {
    let deck: VocabularyDeck

    @Environment(\.modelContext) var modelContext

    @State var allCards: [VocabularyCardRowData] = []
    @State var states: [VocabularyMemoryState] = []
    @State var selection: VocabularyDeckSection? = .words
    @State var searchText = ""
    @State var todayReviewCount = 0
    @State var isImporting = false
    @State var editingCard: VocabularyCardRowData?
    @State var cardToDelete: VocabularyCardRowData?
    @State var cardToSplit: VocabularyCardRowData?
    @State var alert: AppAlert?

    init(deck: VocabularyDeck) {
        self.deck = deck
    }

    var body: some View {
        PaperClipNavigationSplitView {
            List(VocabularyDeckSection.sections(for: deck.kind), selection: $selection) { section in
                Label(section.title(for: deck.kind), systemImage: section.systemImage)
                    .tag(section)
            }
            .paperClipSidebarColumn(deck.title)
        } detail: {
            Group {
                switch selection {
                case .words:
                    wordList(snapshot)
                        .searchable(text: $searchText, prompt: "搜索\(deck.kind.itemName)或释义")
                case .contextPractice: VocabularyContextPracticeView(deck: deck)
                case .mastery: VocabularyMasteryView(deck: deck)
                case .scores: VocabularyStudySessionsView(deck: deck)
                case .settings: VocabularyDeckSettingsView(deck: deck)
                case nil: ContentUnavailableView("请选择内容", systemImage: "character.book.closed")
                }
            }
            .navigationTitle(selection?.title(for: deck.kind) ?? deck.title)
        }
        .vocabularyDeckPresentation(owner: self)
    }

    var deckRefreshID: String {
        "\(deck.id.uuidString):\(deck.updatedAt.timeIntervalSinceReferenceDate)"
    }
}
