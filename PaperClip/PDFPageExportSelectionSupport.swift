import Foundation

struct PDFPageExportSelectionSnapshot: Equatable {
    let pageCount: Int
    let selectedCount: Int
    let hasSelection: Bool
    let allSelected: Bool
    let canToggleAll: Bool
    let canExport: Bool

    init(pageCount: Int?, selectedIndices: Set<Int>, isRendering: Bool) {
        let resolvedPageCount = pageCount ?? 0
        self.pageCount = resolvedPageCount
        self.selectedCount = selectedIndices.count
        self.hasSelection = !selectedIndices.isEmpty
        self.allSelected = PDFPageExportSelectionSupport.isAllSelected(
            selectedIndices: selectedIndices,
            pageCount: resolvedPageCount
        )
        self.canToggleAll = resolvedPageCount > 0
        self.canExport = hasSelection && !isRendering
    }

    var selectionTitle: String {
        selectionTitle()
    }

    func selectionTitle(emptyTitle: String = "选择页面", includesTotal: Bool = true) -> String {
        guard hasSelection else { return emptyTitle }
        return includesTotal
            ? "已选 \(selectedCount) / \(pageCount) 页"
            : "已选 \(selectedCount) 页"
    }

    func navigationTitle(hasGeneratedImage: Bool) -> String {
        hasGeneratedImage ? "页面长图" : selectionTitle
    }
}

enum PDFPageExportSelectionSupport {
    static func isAllSelected(
        selectedIndices: Set<Int>,
        pageCount: Int
    ) -> Bool {
        PDFPageSelectionSet.isAllSelected(
            selectedIndices: selectedIndices,
            pageCount: pageCount
        )
    }

    static func toggledAllSelection(
        selectedIndices: Set<Int>,
        pageCount: Int
    ) -> Set<Int> {
        PDFPageSelectionSet.toggledAll(
            selectedIndices: selectedIndices,
            pageCount: pageCount
        )
    }

    static func canTogglePage(
        index: Int,
        selectedIndices: Set<Int>,
        maxSelectionCount: Int?
    ) -> Bool {
        PDFPageSelectionSet.canTogglePage(
            index: index,
            selectedIndices: selectedIndices,
            maxSelectionCount: maxSelectionCount
        )
    }

    static func toggledPageSelection(
        index: Int,
        selectedIndices: Set<Int>,
        maxSelectionCount: Int?
    ) -> Set<Int> {
        PDFPageSelectionSet.toggledPage(
            index: index,
            selectedIndices: selectedIndices,
            maxSelectionCount: maxSelectionCount
        )
    }

    static func sortedUniqueIndices(
        _ indices: [Int],
        maximumCount: Int,
        pageCount: Int
    ) -> [Int]? {
        PDFPageSelectionSet.sortedUniqueIndices(
            indices,
            maximumCount: maximumCount,
            pageCount: pageCount
        )
    }
}
