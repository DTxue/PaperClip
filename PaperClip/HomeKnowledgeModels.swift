import Foundation

struct KnowledgeItemListRowData: Identifiable, Hashable {
    let id: UUID
    let summary: String
    let subject: String
    let diaryDate: Date

    static var propertiesToFetch: [PartialKeyPath<KnowledgeItem>] {
        [
            \.id,
            \.summary,
            \.subject,
            \.diaryDate,
            \.status,
            \.createdAt
        ]
    }

    init(item: KnowledgeItem) {
        id = item.id
        summary = item.summary
        subject = item.subject
        diaryDate = item.diaryDate
    }
}

struct HomeKnowledgeSnapshot {
    let subjects: [String]
    let visibleItems: [KnowledgeItemListRowData]

    init(items: [KnowledgeItemListRowData], selectedSubject: String) {
        var subjectSet: Set<String> = []
        var visibleItems: [KnowledgeItemListRowData] = []
        visibleItems.reserveCapacity(items.count)
        let normalizedSubject = selectedSubject.trimmingCharacters(in: .whitespacesAndNewlines)

        for item in items {
            let category = Self.category(from: item.subject)
            if !category.isEmpty {
                subjectSet.insert(category)
            }

            if normalizedSubject.isEmpty
                || item.subject == normalizedSubject
                || item.subject.hasPrefix(normalizedSubject + "·") {
                visibleItems.append(item)
            }
        }

        self.subjects = Self.sortedSubjects(subjectSet)
        self.visibleItems = visibleItems
    }

    static func category(from subject: String) -> String {
        let trimmed = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let dot = trimmed.firstIndex(of: "·") else { return trimmed }
        return String(trimmed[trimmed.startIndex..<dot])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func sortedSubjects(_ subjects: Set<String>) -> [String] {
        let knownOrder = Dictionary(
            uniqueKeysWithValues: Subject.allCases.enumerated().map { ($0.element.rawValue, $0.offset) }
        )
        return subjects.sorted {
            let lhsRank = knownOrder[$0] ?? Int.max
            let rhsRank = knownOrder[$1] ?? Int.max
            if lhsRank != rhsRank { return lhsRank < rhsRank }
            return $0 < $1
        }
    }
}
