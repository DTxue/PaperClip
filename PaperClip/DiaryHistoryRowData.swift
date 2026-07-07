import Foundation

enum DiaryHistoryIndicatorKind: CaseIterable {
    case learned
    case confused
    case noted
    case inspired

    var systemImage: String {
        switch self {
        case .learned: return "book.fill"
        case .confused: return "questionmark.circle.fill"
        case .noted: return "note.text"
        case .inspired: return "lightbulb.fill"
        }
    }
}

struct DiaryHistoryIndicator: Hashable {
    let kind: DiaryHistoryIndicatorKind
    let isActive: Bool
}

struct DiaryHistoryRowData: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let hasLearned: Bool
    let hasConfused: Bool
    let hasNoted: Bool
    let hasInspired: Bool

    init(
        id: UUID,
        date: Date,
        hasLearned: Bool,
        hasConfused: Bool,
        hasNoted: Bool,
        hasInspired: Bool
    ) {
        self.id = id
        self.date = date
        self.hasLearned = hasLearned
        self.hasConfused = hasConfused
        self.hasNoted = hasNoted
        self.hasInspired = hasInspired
    }

    init(entry: DiaryEntry) {
        let contentPresence = entry.contentPresence
        self.init(
            id: entry.id,
            date: entry.date,
            hasLearned: contentPresence.hasLearned,
            hasConfused: contentPresence.hasConfused,
            hasNoted: contentPresence.hasNoted,
            hasInspired: contentPresence.hasInspired
        )
    }

    var indicators: [DiaryHistoryIndicator] {
        [
            DiaryHistoryIndicator(kind: .learned, isActive: hasLearned),
            DiaryHistoryIndicator(kind: .confused, isActive: hasConfused),
            DiaryHistoryIndicator(kind: .noted, isActive: hasNoted),
            DiaryHistoryIndicator(kind: .inspired, isActive: hasInspired)
        ]
    }

    static var propertiesToFetch: [PartialKeyPath<DiaryEntry>] {
        [
            \.id,
            \.date,
            \.learned,
            \.confused,
            \.noted,
            \.inspired
        ]
    }
}
