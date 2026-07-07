import SwiftUI

struct VocabularyHomeOverview: View {
    let deckCount: Int
    let snapshot: VocabularyHomeSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("学习概况")
                .font(.title2.bold())
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                VocabularyMetricTile(
                    value: "\(deckCount)",
                    label: "词集",
                    icon: "books.vertical.fill",
                    color: Color.accentColor
                )
                VocabularyMetricTile(
                    value: "\(snapshot.totalCardCount)",
                    label: "单词",
                    icon: "character.book.closed.fill",
                    color: Color.blue
                )
                VocabularyMetricTile(
                    value: "\(snapshot.dueCount)",
                    label: "今日待复习次数",
                    icon: "clock.fill",
                    color: Color.orange
                )
            }
        }
    }
}

struct VocabularyHomeDeckGrid: View {
    let decks: [VocabularyDeckRowData]
    let snapshot: VocabularyHomeSnapshot
    let onDelete: (VocabularyDeckRowData) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("我的词集")
                .font(.title2.bold())
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 16)], spacing: 16) {
                ForEach(decks) { deck in
                    NavigationLink {
                        VocabularyDeckLoader(deckID: deck.id)
                    } label: {
                        VocabularyHomeDeckCard(
                            title: deck.title,
                            cardCount: cardCount(for: deck)
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("删除", systemImage: "trash", role: .destructive) {
                            onDelete(deck)
                        }
                    }
                    .accessibilityLabel("\(deck.title)，\(cardCount(for: deck))个单词")
                }
            }
        }
    }

    private func cardCount(for deck: VocabularyDeckRowData) -> Int {
        snapshot.cardCountByDeckID[deck.id, default: 0]
    }
}

private struct VocabularyHomeDeckCard: View {
    let title: String
    let cardCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "character.book.closed.fill")
                .font(.title)
                .foregroundStyle(.accent)
            Text(title)
                .font(.headline)
                .lineLimit(2)
            Text("\(cardCount) 个词组")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(.quaternary) }
    }
}
