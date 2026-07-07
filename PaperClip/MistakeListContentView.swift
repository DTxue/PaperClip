import SwiftUI

extension SubjectMistakesView {
    var mistakeContent: some View {
        let snapshot = mistakeSnapshot

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("\(snapshot.filteredCards.count) 张错题")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !cards.isEmpty {
                    MasteryProgressBar(summary: snapshot.masterySummary)
                }

                MistakeStatusTypeFilters(
                    selectedStatus: $selectedStatus,
                    selectedQuestionType: $selectedQuestionType
                )

                if snapshot.allSources.count > 1 {
                    MistakeSourceFilterView(
                        sources: snapshot.allSources,
                        selectedSource: $selectedSource
                    )
                }

                if !snapshot.topTags.isEmpty {
                    MistakeTagFilterView(
                        tags: snapshot.topTags,
                        selectedTag: $selectedTag
                    )
                }

                if snapshot.filteredCards.isEmpty {
                    ContentUnavailableView(
                        snapshot.emptyState.title,
                        systemImage: "rectangle.stack",
                        description: Text(snapshot.emptyState.description)
                    )
                    .frame(maxWidth: .infinity, minHeight: 380)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 280), spacing: 18)],
                        spacing: 18
                    ) {
                        ForEach(snapshot.filteredCards) { card in
                            Button { editingCard = card } label: {
                                MistakeCardTile(
                                    card: card,
                                    practiceRoundCount: practiceRoundCountByCardID[card.id, default: 0]
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("编辑错题卡")
                            .contextMenu {
                                Button("编辑", systemImage: "pencil") { editingCard = card }
                                if card.status != MasteryStatus.mastered.rawValue {
                                    Button("升一级掌握状态", systemImage: "arrow.up.circle") {
                                        promoteStatus(for: card)
                                    }
                                }
                                Divider()
                                Button("删除", systemImage: "trash", role: .destructive) {
                                    deleteCard(card)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: 1_400, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .searchable(text: $searchText, prompt: "搜索标签、备注或试卷名")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    paperSelectionCards = snapshot.filteredCards
                    isPaperSelectionPresented = true
                } label: {
                    Label("出卷", systemImage: "doc.text.below.ecg")
                }
                .disabled(snapshot.filteredCards.isEmpty)
            }
        }
    }
}
