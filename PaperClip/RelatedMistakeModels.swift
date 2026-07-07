import Foundation

struct RelatedMistakeSnapshot: Identifiable {
    let card: MistakeCardRowData
    let sharedTags: [String]

    var id: UUID { card.id }

    var sharedTagPreviewText: String {
        MistakeTagDisplay.preview(sharedTags, limit: 3)
    }

    var sharedTagsAccessibilityText: String {
        MistakeTagDisplay.accessibilityList(sharedTags)
    }
}

enum RelatedMistakeMatcher {
    private struct CandidateIndex {
        let candidatesByID: [UUID: MistakeCardRowData]
        let idsByTag: [String: Set<UUID>]

        init(candidates: [MistakeCardRowData]) {
            var candidatesByID: [UUID: MistakeCardRowData] = [:]
            candidatesByID.reserveCapacity(candidates.count)
            var idsByTag: [String: Set<UUID>] = [:]
            for card in candidates {
                candidatesByID[card.id] = card
                for tag in card.tags {
                    idsByTag[tag, default: []].insert(card.id)
                }
            }
            self.candidatesByID = candidatesByID
            self.idsByTag = idsByTag
        }

        func candidateIDs(sharingAny tags: Set<String>) -> Set<UUID> {
            var ids: Set<UUID> = []
            for tag in tags {
                guard let taggedIDs = idsByTag[tag] else { continue }
                ids.formUnion(taggedIDs)
            }
            return ids
        }
    }

    static func topMatches(
        candidates: [MistakeCardRowData],
        currentCardID: UUID,
        tags: [String],
        limit: Int = 5
    ) -> [RelatedMistakeSnapshot] {
        let myTags = Set(tags)
        guard !myTags.isEmpty else { return [] }

        let index = CandidateIndex(candidates: candidates)
        var topMatches: [RelatedMistakeSnapshot] = []
        topMatches.reserveCapacity(limit)
        for id in index.candidateIDs(sharingAny: myTags) where id != currentCardID {
            guard let related = index.candidatesByID[id] else { continue }
            let sharedTags = related.tags.filter(myTags.contains)
            guard !sharedTags.isEmpty else { continue }
            insert(
                RelatedMistakeSnapshot(card: related, sharedTags: sharedTags.sorted()),
                into: &topMatches,
                limit: limit
            )
        }
        return topMatches
    }

    private static func insert(
        _ match: RelatedMistakeSnapshot,
        into topMatches: inout [RelatedMistakeSnapshot],
        limit: Int
    ) {
        let insertIndex = topMatches.firstIndex { isRanked(match, before: $0) }
            ?? topMatches.count
        guard insertIndex < limit else { return }
        topMatches.insert(match, at: insertIndex)
        if topMatches.count > limit {
            topMatches.removeLast()
        }
    }

    private static func isRanked(
        _ lhs: RelatedMistakeSnapshot,
        before rhs: RelatedMistakeSnapshot
    ) -> Bool {
        if lhs.sharedTags.count != rhs.sharedTags.count {
            return lhs.sharedTags.count > rhs.sharedTags.count
        }
        return lhs.card.createdAt > rhs.card.createdAt
    }
}
