import SwiftUI
import SwiftData

struct VocabularyHomeView: View {
    @Environment(\.modelContext) var modelContext

    @State var decks: [VocabularyDeckRowData] = []
    @State var snapshot = VocabularyHomeSnapshot.empty
    @State private var isCreatingDeck = false
    @State private var deckToDelete: VocabularyDeckRowData?
    @State var alert: AppAlert?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if decks.isEmpty {
                    ContentUnavailableView {
                        Label("还没有单词集", systemImage: "character.book.closed")
                    } description: {
                        Text("创建词集后，可通过多种 TXT 文本格式导入单词。")
                    } actions: {
                        Button("创建词集", systemImage: "plus") {
                            isCreatingDeck = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, minHeight: 360)
                } else {
                    VocabularyHomeOverview(deckCount: decks.count, snapshot: snapshot)
                    VocabularyHomeDeckGrid(decks: decks, snapshot: snapshot) { deck in
                        deckToDelete = deck
                    }
                }
            }
            .frame(maxWidth: 1_200, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("英语")
        .onAppear {
            refreshHome()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("创建词集", systemImage: "plus") {
                    isCreatingDeck = true
                }
            }
        }
        .sheet(isPresented: $isCreatingDeck, onDismiss: {
            refreshHome()
        }) {
            NavigationStack {
                VocabularyDeckCreateView()
            }
        }
        .deleteConfirmationDialog(
            item: $deckToDelete,
            title: { "删除词集「\($0.title)」？" },
            message: { _ in "该词集中的单词、复习记录和手写记录都会删除，无法撤销。" },
            onDelete: deleteDeck
        )
        .appAlert($alert)
    }

}
