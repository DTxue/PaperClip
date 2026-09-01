import SwiftUI

extension VocabularyDeckView {
    func wordList(_ snapshot: VocabularyDeckSnapshot) -> some View {
        List {
            if snapshot.visibleCards.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "还没有\(deck.kind.itemName)" : "没有匹配结果",
                    systemImage: searchText.isEmpty ? deck.kind.systemImage : "magnifyingglass",
                    description: Text(
                        searchText.isEmpty
                            ? "新增\(deck.kind.itemName)或导入 TXT 文本。"
                            : "尝试其他关键词。"
                    )
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
                                if deck.kind.usesWordSpecificFeatures, !card.phonetic.isEmpty {
                                    Text(card.phonetic)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            if deck.kind.usesWordSpecificFeatures,
                               let englishDefinition = card.displayEnglishDefinition {
                                Text(englishDefinition)
                                    .font(.subheadline)
                                    .foregroundStyle(.tint)
                                    .lineLimit(2)
                            }
                            Text(card.definition)
                                .foregroundStyle(.secondary)
                            if deck.kind.usesWordSpecificFeatures, !card.example.isEmpty {
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
                        if deck.kind.usesWordSpecificFeatures {
                            Button("拆分", systemImage: "scissors") {
                                cardToSplit = card
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
    }

}
