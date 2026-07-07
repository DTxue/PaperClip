import SwiftUI

extension VocabularyDeckView {
    func wordList(_ snapshot: VocabularyDeckSnapshot) -> some View {
        List {
            if snapshot.visibleCards.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "还没有单词" : "没有匹配结果",
                    systemImage: searchText.isEmpty ? "textformat.abc" : "magnifyingglass",
                    description: Text(searchText.isEmpty ? "新增单词或导入 TXT 文本。" : "尝试其他关键词。")
                )
                .listRowSeparator(.hidden)
            } else {
                ForEach(snapshot.visibleCards) { card in
                    Button {
                        editingCard = card
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(card.term)
                                    .font(.headline)
                                if !card.phonetic.isEmpty {
                                    Text(card.phonetic)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Text(card.definition)
                                .foregroundStyle(.secondary)
                            if !card.example.isEmpty {
                                Text(card.example)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button("删除", systemImage: "trash", role: .destructive) {
                            cardToDelete = card
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button("拆分", systemImage: "scissors") {
                            cardToSplit = card
                        }
                        .tint(.blue)
                    }
                }
            }
        }
    }

    func deckOverview(_ snapshot: VocabularyDeckSnapshot) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 14)], spacing: 14) {
                VocabularyMetricTile(value: "\(snapshot.visibleCards.count)", label: "单词", icon: "character.book.closed.fill", color: Color.blue)
                VocabularyMetricTile(
                    value: "\(snapshot.dueDirectionCount)",
                    label: "到期记忆方向",
                    icon: "clock.fill",
                    color: Color.orange
                )
                VocabularyMetricTile(
                    value: "\(snapshot.todayReviewCount)",
                    label: "今日复习",
                    icon: "checkmark.circle.fill",
                    color: Color.green
                )
            }
            .padding(28)
        }
    }
}
