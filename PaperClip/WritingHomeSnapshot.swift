import Foundation

struct WritingHomeSnapshot {
    let visiblePrompts: [WritingPromptRowData]
    let latestDraftByPromptID: [UUID: WritingDraftRowData]
    let latestReviewByPromptID: [UUID: WritingReviewRowData]

    init(
        prompts: [WritingPromptRowData],
        drafts: [WritingDraftRowData],
        reviews: [WritingReviewRowData],
        searchText: String
    ) {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        var visiblePrompts: [WritingPromptRowData] = []
        visiblePrompts.reserveCapacity(prompts.count)
        var visiblePromptIDs: Set<UUID> = []
        visiblePromptIDs.reserveCapacity(prompts.count)
        for prompt in prompts where prompt.matchesSearch(normalizedSearch) {
            visiblePrompts.append(prompt)
            visiblePromptIDs.insert(prompt.id)
        }

        self.visiblePrompts = visiblePrompts
        self.latestDraftByPromptID = Self.latestByPromptID(
            drafts,
            visiblePromptIDs: visiblePromptIDs,
            promptID: \.promptID,
            timestamp: \.updatedAt
        )
        self.latestReviewByPromptID = Self.latestByPromptID(
            reviews,
            visiblePromptIDs: visiblePromptIDs,
            promptID: \.promptID,
            timestamp: \.createdAt
        )
    }

    private static func latestByPromptID<Row>(
        _ rows: [Row],
        visiblePromptIDs: Set<UUID>,
        promptID: KeyPath<Row, UUID>,
        timestamp: KeyPath<Row, Date>
    ) -> [UUID: Row] {
        var latest: [UUID: Row] = [:]
        latest.reserveCapacity(min(visiblePromptIDs.count, rows.count))
        for row in rows {
            let id = row[keyPath: promptID]
            guard visiblePromptIDs.contains(id) else { continue }
            if let current = latest[id],
               current[keyPath: timestamp] >= row[keyPath: timestamp] {
                continue
            }
            latest[id] = row
        }
        return latest
    }
}

enum WritingRecentMetadataFetchPlan {
    static func limit(promptCount: Int) -> Int {
        guard promptCount > 0 else { return 0 }
        return min(1_000, max(200, promptCount * 2))
    }
}
