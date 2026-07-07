import Foundation

enum VisibleElementDiff {
    static func elementsToRemove<Element: Hashable>(
        existing: some Sequence<Element>,
        visible: some Sequence<Element>
    ) -> [Element] {
        let visibleSet = Set(visible)
        return existing.filter { !visibleSet.contains($0) }
    }
}
