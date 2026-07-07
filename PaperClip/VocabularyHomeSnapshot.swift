import Foundation

struct VocabularyHomeSnapshot {
    let totalCardCount: Int
    let dueCount: Int
    let cardCountByDeckID: [UUID: Int]

    static let empty = VocabularyHomeSnapshot(
        totalCardCount: 0,
        futureDirectionKeys: [],
        cardCountByDeckID: [:]
    )

    init(
        totalCardCount: Int,
        futureDirectionKeys: Set<VocabularyMemoryLookupKey>,
        cardCountByDeckID: [UUID: Int]
    ) {
        self.totalCardCount = totalCardCount
        dueCount = VocabularyHomeDueCount.count(
            totalCardCount: totalCardCount,
            futureDirectionKeyCount: futureDirectionKeys.count
        )
        self.cardCountByDeckID = cardCountByDeckID
    }

    init(
        deckIDs: [UUID],
        cards: [VocabularyHomeCardCountInput],
        futureStates: [VocabularyHomeFutureStateInput]
    ) {
        self.init(
            deckIDs: deckIDs,
            cards: cards,
            futureStates: futureStates,
            cardFields: { ($0.id, $0.deckID) },
            futureStateFields: { ($0.deckID, $0.cardID, $0.direction) }
        )
    }

    init(
        deckIDs: [UUID],
        fetchedCards: [VocabularyCard],
        fetchedFutureStates: [VocabularyMemoryState]
    ) {
        self.init(
            deckIDs: deckIDs,
            cards: fetchedCards,
            futureStates: fetchedFutureStates,
            cardFields: { ($0.id, $0.deckID) },
            futureStateFields: { ($0.deckID, $0.cardID, $0.direction) }
        )
    }

    private init<CardSequence: Sequence, FutureStateSequence: Sequence>(
        deckIDs: [UUID],
        cards: CardSequence,
        futureStates: FutureStateSequence,
        cardFields: (CardSequence.Element) -> (id: UUID, deckID: UUID),
        futureStateFields: (FutureStateSequence.Element) -> (deckID: UUID?, cardID: UUID, direction: String)
    ) {
        let deckIDSet = Set(deckIDs)
        var cardCountByDeckID = Dictionary(
            uniqueKeysWithValues: deckIDs.map { ($0, 0) }
        )
        var validCardIDs: Set<UUID> = []
        var totalCardCount = 0

        for card in cards {
            let fields = cardFields(card)
            guard deckIDSet.contains(fields.deckID) else {
                continue
            }
            cardCountByDeckID[fields.deckID, default: 0] += 1
            validCardIDs.insert(fields.id)
            totalCardCount += 1
        }

        var futureDirectionKeys: Set<VocabularyMemoryLookupKey> = []
        for state in futureStates {
            let fields = futureStateFields(state)
            guard let deckID = fields.deckID,
                  deckIDSet.contains(deckID),
                  validCardIDs.contains(fields.cardID)
            else {
                continue
            }
            futureDirectionKeys.insert(
                VocabularyMemoryLookupKey(cardID: fields.cardID, direction: fields.direction)
            )
        }

        self.init(
            totalCardCount: totalCardCount,
            futureDirectionKeys: futureDirectionKeys,
            cardCountByDeckID: cardCountByDeckID
        )
    }
}
