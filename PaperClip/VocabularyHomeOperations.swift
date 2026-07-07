import Foundation

extension VocabularyHomeView {
    func refreshHome() {
        do {
            decks = try modelContext.fetchVocabularyDecks(
                propertiesToFetch: VocabularyDeckRowData.propertiesToFetch
            ).map(VocabularyDeckRowData.init)
            refreshSnapshot()
        } catch {
            decks = []
            snapshot = .empty
            alert = AppAlert(title: "无法读取词集", error: error)
        }
    }

    func refreshSnapshot() {
        do {
            let cards = try modelContext.fetchVocabularyCards(
                propertiesToFetch: VocabularyCard.homeCountPropertiesToFetch
            )
            let futureStates = try modelContext.fetchFutureVocabularyMemoryStates(
                after: Date(),
                propertiesToFetch: VocabularyMemoryState.futureDuePropertiesToFetch
            )
            snapshot = VocabularyHomeSnapshot(
                deckIDs: decks.map(\.id),
                fetchedCards: cards,
                fetchedFutureStates: futureStates
            )
        } catch {
            snapshot = .empty
            alert = AppAlert(title: "无法读取词汇统计", error: error)
        }
    }

    func deleteDeck(_ row: VocabularyDeckRowData) {
        let deckID = row.id
        do {
            try modelContext.deleteVocabularyDeckCascade(deckID: deckID)
            try modelContext.saveOrRollbackIfNeeded()
            refreshHome()
        } catch {
            alert = AppAlert(title: "无法删除词集", error: error)
        }
    }
}
