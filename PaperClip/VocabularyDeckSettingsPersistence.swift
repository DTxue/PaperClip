import Foundation

extension VocabularyDeckSettingsView {
    func deleteDeck(_ request: VocabularyDeckDeleteRequest) {
        do {
            isDeletingDeck = true
            cancelGeneration()
            cancelDefinitionGeneration()
            try modelContext.deleteVocabularyDeckCascade(deckID: request.id)
            try modelContext.saveOrRollbackIfNeeded()
            dismiss()
        } catch {
            isDeletingDeck = false
            alert = AppAlert(title: "无法删除\(deck.kind.collectionName)", error: error)
        }
    }

    func refreshDeckSettingsSnapshot() {
        let deckID = deck.id
        do {
            cards = try modelContext.fetchVocabularyCards(
                deckID: deckID,
                propertiesToFetch: VocabularyCard.deckSettingsPropertiesToFetch
            )
            refreshFreshCacheCount()
        } catch {
            cards = []
            freshCacheCount = 0
            saveError = "无法读取\(deck.kind.collectionName)设置：\(error.localizedDescription)"
        }
    }

    func saveDeckTitle() {
        let trimmed = titleDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != deck.title else { return }
        deck.title = trimmed
        saveDeckSettings()
    }

    func saveDeckSettings() {
        let schedulerVersion = VocabularySchedulingCore.algorithmVersion
        if deck.schedulerVersion != schedulerVersion {
            deck.schedulerVersion = schedulerVersion
        }
        guard modelContext.hasChanges else { return }

        deck.updatedAt = .now
        do {
            try modelContext.saveOrRollbackIfNeeded()
            saveError = nil
        } catch {
            saveError = "无法保存\(deck.kind.collectionName)设置：\(error.localizedDescription)"
        }
    }

    func refreshFreshCacheCount() {
        let deckID = deck.id
        var termByID: [UUID: String] = [:]
        termByID.reserveCapacity(cards.count)
        for card in cards {
            termByID[card.id] = card.term
        }

        do {
            let caches = try modelContext.fetchVocabularyDistractorCaches(
                deckID: deckID,
                propertiesToFetch: VocabularyDistractorCache.freshnessPropertiesToFetch
            )
            freshCacheCount = caches.reduce(into: 0) { count, cache in
                if termByID[cache.cardID] == cache.cardTermSnapshot {
                    count += 1
                }
            }
        } catch {
            freshCacheCount = 0
            saveError = "无法读取干扰词库状态：\(error.localizedDescription)"
        }
    }
}
