import Foundation

struct DiaryEntryContentPresence: Equatable {
    let hasLearned: Bool
    let hasConfused: Bool
    let hasNoted: Bool
    let hasInspired: Bool

    init(
        learned: String,
        confused: String,
        noted: String,
        inspired: String
    ) {
        hasLearned = Self.hasMeaningfulText(learned)
        hasConfused = Self.hasMeaningfulText(confused)
        hasNoted = Self.hasMeaningfulText(noted)
        hasInspired = Self.hasMeaningfulText(inspired)
    }

    var hasAnyContent: Bool {
        hasLearned || hasConfused || hasNoted || hasInspired
    }

    var hasAIProcessableContent: Bool {
        hasLearned || hasConfused || hasInspired
    }

    private static func hasMeaningfulText(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
