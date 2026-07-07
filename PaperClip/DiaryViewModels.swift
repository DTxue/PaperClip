import Foundation

struct DiaryEntryEditableContent {
    var learned: String
    var confused: String
    var noted: String
    var inspired: String

    init(
        learned: String = "",
        confused: String = "",
        noted: String = "",
        inspired: String = ""
    ) {
        self.learned = learned
        self.confused = confused
        self.noted = noted
        self.inspired = inspired
    }

    init(entry: DiaryEntry?) {
        self.init(
            learned: entry?.learned ?? "",
            confused: entry?.confused ?? "",
            noted: entry?.noted ?? "",
            inspired: entry?.inspired ?? ""
        )
    }

    var hasInput: Bool {
        contentPresence.hasAnyContent
    }

    var contentPresence: DiaryEntryContentPresence {
        DiaryEntryContentPresence(
            learned: learned,
            confused: confused,
            noted: noted,
            inspired: inspired
        )
    }

    func differs(from entry: DiaryEntry) -> Bool {
        learned != entry.learned
            || confused != entry.confused
            || noted != entry.noted
            || inspired != entry.inspired
    }

    func aiContentDiffers(from entry: DiaryEntry) -> Bool {
        learned != entry.learned
            || confused != entry.confused
            || inspired != entry.inspired
    }

    func apply(to entry: DiaryEntry) {
        entry.learned = learned
        entry.confused = confused
        entry.noted = noted
        entry.inspired = inspired
    }

    mutating func replace(with entry: DiaryEntry?) {
        self = DiaryEntryEditableContent(entry: entry)
    }

    mutating func reset() {
        self = DiaryEntryEditableContent()
    }
}

enum DiaryDetailPhase {
    case readOnly
    case editing
    case drafting
}
