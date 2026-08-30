import Foundation

struct VocabularyStudyQueuePlan {
    typealias FreshSampler = VocabularyStudyQueueBuilder.FreshSampler

    let queueLimit: Int
    let stateByCardID: [UUID: VocabularyMemoryState]
    let due: [(card: VocabularyCard, dueDate: Date)]
    let freshCandidates: [VocabularyCard]

    init(cards: [VocabularyCard], states: [VocabularyMemoryState], maximumQueueCount: Int, now: Date) {
        queueLimit = max(0, maximumQueueCount)
        stateByCardID = Self.indexStates(states)

        var due: [(card: VocabularyCard, dueDate: Date)] = []
        var freshCandidates: [VocabularyCard] = []
        due.reserveCapacity(queueLimit)

        for card in cards {
            guard let state = stateByCardID[card.id] else {
                freshCandidates.append(card)
                continue
            }
            if state.dueDate <= now {
                VocabularyStudyQueueRanking.insertDueCard((card, state.dueDate), into: &due, limit: queueLimit)
            }
        }

        self.due = due
        self.freshCandidates = freshCandidates
    }

    func makeQueue(cards: [VocabularyCard], deck: VocabularyDeck, now: Date, freshSampler: FreshSampler) -> [VocabularyCard] {
        guard queueLimit > 0 else { return [] }
        var queue = due.map(\.card)
        queue.reserveCapacity(queueLimit)
        guard queue.count < queueLimit else { return Array(queue.prefix(queueLimit)) }

        let fresh = freshSampler(freshCandidates, min(max(0, deck.dailyNewLimit), queueLimit - queue.count))
        let selectedFreshIDs = Set(fresh.map(\.id))
        for card in fresh {
            queue.append(card)
            if queue.count == queueLimit { return queue }
        }

        appendWeakCards(from: cards, to: &queue, selectedFreshIDs: selectedFreshIDs, deck: deck, now: now)
        return queue
    }

    private func appendWeakCards(
        from cards: [VocabularyCard],
        to queue: inout [VocabularyCard],
        selectedFreshIDs: Set<UUID>,
        deck: VocabularyDeck,
        now: Date
    ) {
        let weakLimit = queueLimit - queue.count
        var weak: [(card: VocabularyCard, priority: Double)] = []
        weak.reserveCapacity(weakLimit)

        for card in cards {
            if let state = stateByCardID[card.id] {
                if state.dueDate > now {
                    insertWeakCard(card, state: state, into: &weak, limit: weakLimit, deck: deck, now: now)
                }
            } else if !selectedFreshIDs.contains(card.id) {
                insertWeakCard(card, state: nil, into: &weak, limit: weakLimit, deck: deck, now: now)
            }
        }

        for item in weak {
            queue.append(item.card)
            if queue.count == queueLimit { return }
        }
    }

    private func insertWeakCard(
        _ card: VocabularyCard,
        state: VocabularyMemoryState?,
        into weak: inout [(card: VocabularyCard, priority: Double)],
        limit: Int,
        deck: VocabularyDeck,
        now: Date
    ) {
        let priority = VocabularyStudyQueueRanking.masteryPriority(card, state: state, deck: deck, now: now)
        VocabularyStudyQueueRanking.insertWeakCard((card, priority), into: &weak, limit: limit)
    }

    private static func indexStates(_ states: [VocabularyMemoryState]) -> [UUID: VocabularyMemoryState] {
        var stateByCardID: [UUID: VocabularyMemoryState] = [:]
        stateByCardID.reserveCapacity(states.count)
        for state in states where stateByCardID[state.cardID] == nil { stateByCardID[state.cardID] = state }
        return stateByCardID
    }
}

enum VocabularyFlashcardQueue {
    static func orderedCards(
        cards: [VocabularyCard],
        states: [VocabularyMemoryState],
        direction: VocabularyDirection,
        now: Date = .now
    ) -> [VocabularyCard] {
        var stateByCardID: [UUID: VocabularyMemoryState] = [:]
        for state in states where state.direction == direction.rawValue {
            if stateByCardID[state.cardID] == nil {
                stateByCardID[state.cardID] = state
            }
        }

        var due: [(card: VocabularyCard, dueDate: Date, originalIndex: Int)] = []
        var remaining: [(card: VocabularyCard, originalIndex: Int)] = []
        due.reserveCapacity(cards.count)
        remaining.reserveCapacity(cards.count)

        for (index, card) in cards.enumerated() {
            if let state = stateByCardID[card.id], state.dueDate <= now {
                due.append((card, state.dueDate, index))
            } else {
                remaining.append((card, index))
            }
        }

        due.sort {
            if $0.dueDate != $1.dueDate {
                return $0.dueDate < $1.dueDate
            }
            return $0.originalIndex < $1.originalIndex
        }

        return due.map(\.card) + remaining.map(\.card)
    }
}
