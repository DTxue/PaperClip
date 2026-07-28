import Foundation

extension VocabularyHomeView {
    func refreshHome() {
        do {
            folders = try modelContext.fetchVocabularyFolders(
                propertiesToFetch: VocabularyFolderRowData.propertiesToFetch
            ).map(VocabularyFolderRowData.init)
            decks = try modelContext.fetchVocabularyDecks(
                propertiesToFetch: VocabularyDeckRowData.propertiesToFetch
            ).map(VocabularyDeckRowData.init)
            refreshSnapshot()
        } catch {
            folders = []
            decks = []
            snapshot = .empty
            alert = AppAlert(title: "无法读取 ENG 内容", error: error)
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

    func moveDeck(_ row: VocabularyDeckRowData, to folderID: UUID?) {
        do {
            guard let deck = try modelContext.fetchVocabularyDeck(id: row.id) else {
                alert = AppAlert(title: "无法移动学习集", message: "该学习集不存在或已被删除。")
                refreshHome()
                return
            }

            if let folderID, try modelContext.fetchVocabularyFolder(id: folderID) == nil {
                alert = AppAlert(title: "无法移动学习集", message: "目标文件夹不存在或已被删除。")
                refreshHome()
                return
            }

            deck.folderID = folderID
            deck.updatedAt = .now
            try modelContext.saveOrRollbackIfNeeded()
            refreshHome()
        } catch {
            alert = AppAlert(title: "无法移动学习集", error: error)
        }
    }

    func removeDeckFromFolder(_ row: VocabularyDeckRowData) {
        moveDeck(row, to: nil)
    }
}
