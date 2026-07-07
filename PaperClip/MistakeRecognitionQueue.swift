import Foundation

struct MistakeRecognitionQueue {
    struct Item: Equatable {
        enum Priority {
            case userInitiated
            case recovery
        }

        let cardID: UUID
        let imagePath: String
        let priority: Priority
    }

    private var userPending: [Item] = []
    private var recoveryPending: [Item] = []
    private var processingIDs: Set<UUID> = []
    private(set) var activeCount = 0
    private(set) var activeRecoveryCount = 0

    mutating func enqueue(cardID: UUID, imagePath: String, priority: Item.Priority) {
        guard !processingIDs.contains(cardID),
              !userPending.contains(where: { $0.cardID == cardID }),
              !recoveryPending.contains(where: { $0.cardID == cardID }) else {
            return
        }
        let item = Item(cardID: cardID, imagePath: imagePath, priority: priority)
        switch priority {
        case .userInitiated:
            userPending.append(item)
        case .recovery:
            recoveryPending.append(item)
        }
    }

    mutating func startNext(maxConcurrent: Int, maxConcurrentRecovery: Int) -> Item? {
        guard activeCount < maxConcurrent, let item = nextItem(maxConcurrentRecovery: maxConcurrentRecovery) else {
            return nil
        }
        processingIDs.insert(item.cardID)
        activeCount += 1
        if item.priority == .recovery {
            activeRecoveryCount += 1
        }
        return item
    }

    mutating func finish(_ item: Item) {
        activeCount = max(activeCount - 1, 0)
        if item.priority == .recovery {
            activeRecoveryCount = max(activeRecoveryCount - 1, 0)
        }
        processingIDs.remove(item.cardID)
    }

    mutating func reset() {
        userPending.removeAll()
        recoveryPending.removeAll()
        processingIDs.removeAll()
        activeCount = 0
        activeRecoveryCount = 0
    }

    private mutating func nextItem(maxConcurrentRecovery: Int) -> Item? {
        if !userPending.isEmpty {
            return userPending.removeFirst()
        }
        guard activeRecoveryCount < maxConcurrentRecovery,
              !recoveryPending.isEmpty else {
            return nil
        }
        return recoveryPending.removeFirst()
    }
}
