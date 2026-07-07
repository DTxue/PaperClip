import Foundation

enum PDFPageSelectionSet {
    static func isAllSelected(
        selectedIndices: Set<Int>,
        pageCount: Int
    ) -> Bool {
        guard pageCount > 0, selectedIndices.count == pageCount else { return false }
        return selectedIndices.allSatisfy { (0 ..< pageCount).contains($0) }
    }

    static func toggledAll(
        selectedIndices: Set<Int>,
        pageCount: Int
    ) -> Set<Int> {
        isAllSelected(selectedIndices: selectedIndices, pageCount: pageCount)
            ? []
            : Set(0..<max(pageCount, 0))
    }

    static func canTogglePage(
        index: Int,
        selectedIndices: Set<Int>,
        maxSelectionCount: Int?
    ) -> Bool {
        if selectedIndices.contains(index) {
            return true
        }
        if let maxSelectionCount {
            return selectedIndices.count < maxSelectionCount
        }
        return true
    }

    static func toggledPage(
        index: Int,
        selectedIndices: Set<Int>,
        maxSelectionCount: Int?
    ) -> Set<Int> {
        var updatedSelection = selectedIndices
        if updatedSelection.contains(index) {
            updatedSelection.remove(index)
        } else if canTogglePage(
            index: index,
            selectedIndices: updatedSelection,
            maxSelectionCount: maxSelectionCount
        ) {
            updatedSelection.insert(index)
        }
        return updatedSelection
    }

    static func sortedUniqueIndices(
        _ indices: [Int],
        maximumCount: Int,
        pageCount: Int
    ) -> [Int]? {
        guard !indices.isEmpty, indices.count <= maximumCount else { return nil }

        var seen: Set<Int> = []
        var uniqueIndices: [Int] = []
        seen.reserveCapacity(indices.count)
        uniqueIndices.reserveCapacity(indices.count)

        for index in indices {
            guard (0 ..< pageCount).contains(index),
                  seen.insert(index).inserted
            else {
                return nil
            }
            uniqueIndices.append(index)
        }

        uniqueIndices.sort()
        return uniqueIndices
    }
}
