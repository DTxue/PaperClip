import SwiftUI

extension VocabularyDeckView {
    var snapshot: VocabularyDeckSnapshot {
        VocabularyDeckSnapshot(
            cards: allCards,
            states: states,
            todayReviewCount: todayReviewCount,
            searchText: searchText
        )
    }
}

extension View {
    func vocabularyDeckPresentation(owner: VocabularyDeckView) -> some View {
        self
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu("开始学习", systemImage: "play.fill") {
                        NavigationLink {
                            VocabularyFlashcardView(deck: owner.deck)
                        } label: {
                            Label("闪卡", systemImage: "rectangle.on.rectangle")
                        }
                        NavigationLink {
                            VocabularyStudyView(deck: owner.deck)
                        } label: {
                            Label("学习", systemImage: "brain.head.profile")
                        }
                        NavigationLink {
                            VocabularyTestView(deck: owner.deck)
                        } label: {
                            Label("测验", systemImage: "checklist")
                        }
                    }
                    .disabled(owner.snapshot.visibleCards.isEmpty)
                    Button("导入\(owner.deck.kind.itemName)", systemImage: "square.and.arrow.down") {
                        owner.isImporting = true
                    }
                }
            }
            .sheet(isPresented: owner.$isImporting, onDismiss: owner.refreshDeckSnapshot) {
                NavigationStack {
                    VocabularyImportView(deck: owner.deck)
                }
            }
            .sheet(item: owner.$editingCard, onDismiss: owner.refreshDeckSnapshot) { card in
                NavigationStack {
                    VocabularyCardEditorLoader(deck: owner.deck, cardID: card.id)
                }
            }
            .sheet(item: owner.$cardToSplit, onDismiss: owner.refreshDeckSnapshot) { card in
                NavigationStack {
                    VocabularyCardSplitLoader(deck: owner.deck, cardID: card.id)
                }
            }
            .deleteConfirmationDialog(
                item: owner.$cardToDelete,
                title: { "删除「\($0.term)」？" },
                onDelete: owner.deleteCard
            )
            .appAlert(owner.$alert)
            .task(id: owner.deckRefreshID) {
                owner.refreshDeckSnapshot()
                owner.refreshTodayReviewCount()
            }
    }
}
