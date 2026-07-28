import Foundation

extension VocabularyDeckView {
    func refreshDeckSnapshot() {
        let deckID = deck.id
        do {
            allCards = try modelContext.fetchVocabularyCards(
                deckID: deckID,
                propertiesToFetch: VocabularyCardRowData.propertiesToFetch
            ).map(VocabularyCardRowData.init)
            states = try modelContext.fetchVocabularyMemoryStates(
                deckID: deckID,
                propertiesToFetch: VocabularyMemoryState.dueLookupPropertiesToFetch
            )
        } catch {
            allCards = []
            states = []
            alert = AppAlert(title: "无法读取\(deck.kind.collectionName)内容", error: error)
        }
    }

    func deleteCard(_ card: VocabularyCardRowData) {
        let cardID = card.id
        do {
            try modelContext.deleteVocabularyCardCascade(cardID: cardID)
            deck.updatedAt = .now
            try modelContext.saveOrRollbackIfNeeded()
            refreshDeckSnapshot()
            refreshTodayReviewCount()
        } catch {
            alert = AppAlert(title: "无法删除\(deck.kind.itemName)", error: error)
        }
    }

    func refreshTodayReviewCount(calendar: Calendar = .current, now: Date = .now) {
        let deckID = deck.id
        let startOfToday = calendar.startOfDay(for: now)
        do {
            todayReviewCount = try modelContext.fetchVocabularyReviewCount(
                deckID: deckID,
                since: startOfToday
            )
        } catch {
            todayReviewCount = 0
            alert = AppAlert(title: "无法读取今日复习数量", error: error)
        }
    }
}
