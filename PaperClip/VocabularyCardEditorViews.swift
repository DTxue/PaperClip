import SwiftUI
import SwiftData

struct VocabularyCardEditorLoader: View {
    @Environment(\.modelContext) private var modelContext
    let deck: VocabularyDeck
    let cardID: UUID
    @State private var card: VocabularyCard?
    @State private var alert: AppAlert?

    var body: some View {
        Group {
            if let card {
                VocabularyCardEditorView(deck: deck, card: card)
            } else {
                ContentUnavailableView(
                    "无法打开\(deck.kind.itemName)",
                    systemImage: deck.kind.systemImage,
                    description: Text("这个\(deck.kind.itemName)可能已被删除。")
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
            alert = AppAlert(title: "无法读取\(deck.kind.itemName)", error: error)
        }
    }
}

struct VocabularyCardEditorView: View {
    let deck: VocabularyDeck
    let card: VocabularyCard

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var draft: VocabularyCardEditDraft
    @State private var alert: AppAlert?

    init(deck: VocabularyDeck, card: VocabularyCard) {
        self.deck = deck
        self.card = card
        _draft = State(initialValue: VocabularyCardEditDraft(card: card))
    }

    var body: some View {
        Form {
            VocabularyCardEditorFormSections(draft: $draft, kind: deck.kind)
        }
        .navigationTitle("编辑\(deck.kind.itemName)")
        .navigationBarTitleDisplayMode(.inline)
        .editSheetToolbar(
            isConfirmDisabled: !draft.canSave,
            onCancel: { dismiss() },
            onConfirm: save
        )
        .appAlert($alert)
    }

    private func save() {
        let snapshot = draft.snapshot

        guard VocabularyCardEditSnapshot(card: card) != snapshot else {
            dismiss()
            return
        }

        snapshot.apply(to: card)
        card.updatedAt = .now
        deck.updatedAt = .now
        do {
            try modelContext.saveOrRollbackIfNeeded()
            dismiss()
        } catch {
            alert = AppAlert(title: "无法保存\(deck.kind.itemName)", error: error)
        }
    }
}
