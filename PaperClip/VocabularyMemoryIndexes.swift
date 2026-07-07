import Foundation

struct VocabularyMemoryLookupKey: Hashable {
    let cardID: UUID
    let direction: String
}

struct VocabularyMemoryStateIndex {
    private var statesByCardDirection: [VocabularyMemoryLookupKey: VocabularyMemoryState] = [:]

    init(_ states: [VocabularyMemoryState]) {
        statesByCardDirection.reserveCapacity(states.count)
        for state in states {
            let key = VocabularyMemoryLookupKey(cardID: state.cardID, direction: state.direction)
            if statesByCardDirection[key] == nil {
                statesByCardDirection[key] = state
            }
        }
    }

    func state(for cardID: UUID, direction: VocabularyDirection) -> VocabularyMemoryState? {
        statesByCardDirection[VocabularyMemoryLookupKey(cardID: cardID, direction: direction.rawValue)]
    }

    func dueDirectionCount(for cardID: UUID, now: Date) -> Int {
        VocabularyDirection.allCases.reduce(0) { count, direction in
            let dueDate = state(for: cardID, direction: direction)?.dueDate ?? .distantPast
            return count + (dueDate <= now ? 1 : 0)
        }
    }
}

struct VocabularyReviewLogIndex {
    private var logsByCardDirection: [VocabularyMemoryLookupKey: [VocabularyReviewLog]] = [:]

    init(_ logs: [VocabularyReviewLog]) {
        logsByCardDirection.reserveCapacity(logs.count)
        for log in logs {
            let key = VocabularyMemoryLookupKey(cardID: log.cardID, direction: log.direction)
            logsByCardDirection[key, default: []].append(log)
        }
    }

    func logs(for cardID: UUID, direction: VocabularyDirection) -> [VocabularyReviewLog] {
        logsByCardDirection[VocabularyMemoryLookupKey(cardID: cardID, direction: direction.rawValue)] ?? []
    }
}
