import Foundation

extension VocabularyStudyView {
    func startSession() {
        fetchSessionData()
        queue = buildQueue()
        index = 0
        sessionStartedAt = .now
        sessionItems = []
        didRecordSession = false
        prepareQuestion()
    }

    func fetchSessionData() {
        let deckID = deck.id

        do {
            let data = try modelContext.fetchVocabularySessionData(
                deckID: deckID,
                direction: .definitionToTerm,
                statePropertiesToFetch: VocabularyMemoryState.sessionPropertiesToFetch
            )
            allCards = data.cards
            states = data.states
        } catch {
            allCards = []
            states = []
            alert = AppAlert(title: "无法读取学习队列", error: error)
        }
    }

    func buildQueue() -> [VocabularyCard] {
        VocabularyStudyQueueBuilder.buildQueue(
            cards: allCards,
            states: states,
            deck: deck,
            maximumQueueCount: maximumQueueCount
        )
    }
}
