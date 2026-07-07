import Foundation

enum WritingPromptDeletionSelection {
    static func targetIDs(
        offsets: IndexSet,
        visiblePrompts: [WritingPromptRowData]
    ) -> Set<UUID> {
        var targetIDs: Set<UUID> = []
        for offset in offsets where visiblePrompts.indices.contains(offset) {
            targetIDs.insert(visiblePrompts[offset].id)
        }
        return targetIDs
    }
}
