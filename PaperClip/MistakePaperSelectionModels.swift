import Foundation

enum PaperSelectionStatusFilter: String, CaseIterable, Identifiable {
    case unmastered
    case review
    case mastered
    case all

    var id: String { rawValue }

    var label: String {
        switch self {
        case .unmastered:
            return "未掌握"
        case .review:
            return "待复习"
        case .mastered:
            return "已掌握"
        case .all:
            return "全部"
        }
    }

    func includes(_ card: MistakeCardRowData) -> Bool {
        switch self {
        case .unmastered:
            return card.status == MasteryStatus.unmastered.rawValue
        case .review:
            return card.status == MasteryStatus.review.rawValue
        case .mastered:
            return card.status == MasteryStatus.mastered.rawValue
        case .all:
            return true
        }
    }
}

struct PaperSelectionSnapshot {
    let displayCards: [MistakeCardRowData]
    let displayCardIDs: Set<UUID>
    let selectedOrderedIDs: [UUID]
    let allSelected: Bool

    init(
        availableCards: [MistakeCardRowData],
        filterStatus: PaperSelectionStatusFilter,
        selectedIDs: Set<UUID>
    ) {
        var cards: [MistakeCardRowData] = []
        var ids: Set<UUID> = []
        cards.reserveCapacity(availableCards.count)
        ids.reserveCapacity(availableCards.count)

        for card in availableCards where filterStatus.includes(card) {
            cards.append(card)
            ids.insert(card.id)
        }

        displayCards = cards
        displayCardIDs = ids
        selectedOrderedIDs = Self.orderedSelectedIDs(from: availableCards, selectedIDs: selectedIDs)
        allSelected = !cards.isEmpty && displayCardIDs.isSubset(of: selectedIDs)
    }

    static func initiallySelectedIDs(from cards: [MistakeCardRowData]) -> Set<UUID> {
        var ids: Set<UUID> = []
        ids.reserveCapacity(cards.count)
        for card in cards where card.status != MasteryStatus.mastered.rawValue {
            ids.insert(card.id)
        }
        return ids
    }

    static func selectedIDs(
        from cards: [MistakeCardRowData],
        filterStatus: PaperSelectionStatusFilter
    ) -> Set<UUID> {
        var ids: Set<UUID> = []
        ids.reserveCapacity(cards.count)
        for card in cards where filterStatus.includes(card) {
            ids.insert(card.id)
        }
        return ids
    }

    static func orderedSelectedIDs(
        from cards: [MistakeCardRowData],
        selectedIDs: Set<UUID>
    ) -> [UUID] {
        cards.compactMap { selectedIDs.contains($0.id) ? $0.id : nil }
    }
}
