import SwiftUI
import SwiftData

struct VocabularyMasteryView: View {
    let deck: VocabularyDeck

    @Environment(\.modelContext) private var modelContext

    @State private var rows: [VocabularyMasteryRowData] = []
    @State private var alert: AppAlert?
    @State private var isResetConfirmationPresented = false

    init(deck: VocabularyDeck) {
        self.deck = deck
    }

    var body: some View {
        let averageMastery = VocabularyMasteryRowBuilder.averageMastery(for: rows)
        let dueDirectionCount = VocabularyMasteryRowBuilder.dueDirectionCount(for: rows)

        return List {
            Section("汇总") {
                LabeledContent("\(deck.kind.listTitle)数", value: "\(rows.count)")
                LabeledContent("平均熟练度", value: VocabularyStudySessionFormat.percent(averageMastery))
                LabeledContent("到期方向", value: "\(dueDirectionCount)")
            }

            Section("\(deck.kind.listTitle)熟练度") {
                if rows.isEmpty {
                    ContentUnavailableView("还没有\(deck.kind.itemName)", systemImage: deck.kind.systemImage)
                } else {
                    ForEach(rows) { row in
                        VocabularyMasteryCardRow(row: row, kind: deck.kind)
                    }
                }
            }
        }
        .task(id: deck.id) {
            refreshRows()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("重置熟练度", systemImage: "arrow.counterclockwise", role: .destructive) {
                    isResetConfirmationPresented = true
                }
                .disabled(rows.isEmpty)
            }
        }
        .confirmationDialog(
            "重置熟练度？",
            isPresented: $isResetConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("重置熟练度", role: .destructive) {
                resetMastery()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("这会清除当前\(deck.kind.collectionName)的熟练度、到期时间和复习记录；\(deck.kind.itemName)内容不会删除。")
        }
        .appAlert($alert)
    }

    private func refreshRows() {
        let deckID = deck.id
        do {
            let cards = try modelContext.fetchVocabularySessionCards(deckID: deckID)
            let states = try modelContext.fetchVocabularyMemoryStates(
                deckID: deckID,
                propertiesToFetch: VocabularyMemoryState.masteryPropertiesToFetch
            )
            let logs = try fetchRecentLogs(cardCount: cards.count)
            rows = VocabularyMasteryRowBuilder.rows(cards: cards, states: states, logs: logs, deck: deck)
        } catch {
            rows = []
            alert = AppAlert(title: "无法读取熟练度数据", error: error)
        }
    }

    private func resetMastery() {
        do {
            try modelContext.resetVocabularyMastery(deckID: deck.id)
            try modelContext.saveOrRollbackIfNeeded()
            refreshRows()
        } catch {
            alert = AppAlert(title: "无法重置熟练度", error: error)
        }
    }

    private func fetchRecentLogs(cardCount: Int) throws -> [VocabularyReviewLog] {
        try modelContext.fetchVocabularyReviewLogs(
            deckID: deck.id,
            limit: VocabularyMasteryRowBuilder.recentLogLimit(cardCount: cardCount),
            propertiesToFetch: VocabularyReviewLog.masteryPropertiesToFetch
        )
    }
}
