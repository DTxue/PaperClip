import CoreGraphics
import Foundation

@main
struct PDFPageExportSelectionSupportTests {
    static func main() {
        testRenderInputSortsIndicesAndLooksUpSelectedData()
        testExportRequestExposesRenderInput()
        testSortedUniqueIndicesValidatesAndSortsInOnePass()
        testPageSelectionSetProvidesSharedSelectionRules()
        testAllSelectionHelpersHandleEmptyAndPartialSelections()
        testSinglePageSelectionHelpersHonorMaximumSelectionCount()
        testSelectionSnapshotSummarizesViewState()
        testPageIndexDisplayHelpers()
        print("PDFPageExportSelectionSupportTests: 8 passed")
    }

    private static func testRenderInputSortsIndicesAndLooksUpSelectedData() {
        let input = PDFPageExportSelectionSupport.renderInput(
            selectedIndices: [3, 1],
            drawings: [
                0: Data([0]),
                1: Data([1]),
                3: Data([3])
            ],
            canvasSizes: [
                1: CGSize(width: 100, height: 200),
                2: CGSize(width: 200, height: 300)
            ]
        )

        expect(input.pageIndices == [1, 3], "page indices should be sorted")
        expect(input.drawings == [1: Data([1]), 3: Data([3])], "drawings should keep selected pages only")
        expect(input.canvasSizes == [1: CGSize(width: 100, height: 200)], "canvas sizes should keep selected pages only")
    }

    private static func testExportRequestExposesRenderInput() {
        let request = PDFPageExportRequest(
            documentURL: URL(fileURLWithPath: "/tmp/source.pdf"),
            selectedIndices: [2, 0],
            drawings: [0: Data([0]), 1: Data([1])],
            canvasSizes: [2: CGSize(width: 240, height: 320)],
            screenScale: 2
        )

        let input = request.renderInput
        expect(input.pageIndices == [0, 2], "request should expose sorted selected page indices")
        expect(input.drawings == [0: Data([0])], "request should expose selected page drawings")
        expect(input.canvasSizes == [2: CGSize(width: 240, height: 320)], "request should expose selected canvas sizes")
    }

    private static func testSortedUniqueIndicesValidatesAndSortsInOnePass() {
        expect(
            PDFPageExportSelectionSupport.sortedUniqueIndices([2, 0, 1], maximumCount: 3, pageCount: 4) == [0, 1, 2],
            "valid indices should be sorted"
        )
        expect(
            PDFPageExportSelectionSupport.sortedUniqueIndices([], maximumCount: 3, pageCount: 4) == nil,
            "empty selections should be rejected"
        )
        expect(
            PDFPageExportSelectionSupport.sortedUniqueIndices([0, 1, 2, 3], maximumCount: 3, pageCount: 4) == nil,
            "selections beyond the maximum should be rejected"
        )
        expect(
            PDFPageExportSelectionSupport.sortedUniqueIndices([0, 0], maximumCount: 3, pageCount: 4) == nil,
            "duplicate indices should be rejected"
        )
        expect(
            PDFPageExportSelectionSupport.sortedUniqueIndices([0, 4], maximumCount: 3, pageCount: 4) == nil,
            "out-of-range indices should be rejected"
        )
    }

    private static func testPageSelectionSetProvidesSharedSelectionRules() {
        expect(
            PDFPageSelectionSet.isAllSelected(selectedIndices: [0, 1], pageCount: 2),
            "shared page selection should detect full valid selections"
        )
        expect(
            PDFPageSelectionSet.toggledAll(selectedIndices: [0, 1], pageCount: 2).isEmpty,
            "shared page selection should clear a full selection"
        )
        expect(
            PDFPageSelectionSet.toggledPage(index: 1, selectedIndices: [], maxSelectionCount: nil) == [1],
            "shared page selection should insert an unselected page"
        )
        expect(
            PDFPageSelectionSet.sortedUniqueIndices([3, 1], maximumCount: 4, pageCount: 5) == [1, 3],
            "shared page selection should sort validated page indices"
        )
    }

    private static func testAllSelectionHelpersHandleEmptyAndPartialSelections() {
        expect(
            !PDFPageExportSelectionSupport.isAllSelected(selectedIndices: [], pageCount: 0),
            "zero-page documents should not report all selected"
        )
        expect(
            !PDFPageExportSelectionSupport.isAllSelected(selectedIndices: [0], pageCount: 3),
            "partial selections should not report all selected"
        )
        expect(
            PDFPageExportSelectionSupport.isAllSelected(selectedIndices: [0, 1, 2], pageCount: 3),
            "all pages should report all selected"
        )
        expect(
            !PDFPageExportSelectionSupport.isAllSelected(selectedIndices: [1, 2, 99], pageCount: 3),
            "out-of-range selections should not report all selected even when counts match"
        )
        expect(
            PDFPageExportSelectionSupport.toggledAllSelection(selectedIndices: [], pageCount: 3) == [0, 1, 2],
            "toggle should select every page when not all pages are selected"
        )
        expect(
            PDFPageExportSelectionSupport.toggledAllSelection(selectedIndices: [0, 1, 2], pageCount: 3).isEmpty,
            "toggle should clear selection when all pages are selected"
        )
        expect(
            PDFPageExportSelectionSupport.toggledAllSelection(selectedIndices: [], pageCount: -1).isEmpty,
            "negative page counts should be treated as empty"
        )
    }

    private static func testSinglePageSelectionHelpersHonorMaximumSelectionCount() {
        expect(
            PDFPageExportSelectionSupport.canTogglePage(
                index: 0,
                selectedIndices: [0],
                maxSelectionCount: 1
            ),
            "selected pages should remain toggleable when the maximum is reached"
        )
        expect(
            !PDFPageExportSelectionSupport.canTogglePage(
                index: 2,
                selectedIndices: [0],
                maxSelectionCount: 1
            ),
            "unselected pages should not be toggleable when the maximum is reached"
        )
        expect(
            PDFPageExportSelectionSupport.toggledPageSelection(
                index: 0,
                selectedIndices: [0],
                maxSelectionCount: 1
            ).isEmpty,
            "toggling a selected page should remove it"
        )
        expect(
            PDFPageExportSelectionSupport.toggledPageSelection(
                index: 2,
                selectedIndices: [0],
                maxSelectionCount: 1
            ) == [0],
            "toggling an unselected page should no-op when the maximum is reached"
        )
        expect(
            PDFPageExportSelectionSupport.toggledPageSelection(
                index: 2,
                selectedIndices: [0],
                maxSelectionCount: 2
            ) == [0, 2],
            "toggling an unselected page should insert it when below the maximum"
        )
    }

    private static func testSelectionSnapshotSummarizesViewState() {
        let loading = PDFPageExportSelectionSnapshot(pageCount: nil, selectedIndices: [], isRendering: false)
        expect(loading.pageCount == 0, "nil page count should resolve to zero")
        expect(loading.selectionTitle == "选择页面", "empty selection should use default title")
        expect(!loading.canToggleAll, "zero page count should not allow toggling all")

        let selected = PDFPageExportSelectionSnapshot(pageCount: 3, selectedIndices: [0, 2], isRendering: false)
        expect(selected.pageCount == 3, "snapshot should expose resolved page count")
        expect(selected.selectedCount == 2, "snapshot should count selected pages")
        expect(selected.hasSelection, "snapshot should report non-empty selection")
        expect(!selected.allSelected, "partial selection should not report all selected")
        expect(selected.canToggleAll, "positive page count should allow toggling all")
        expect(selected.canExport, "non-rendering non-empty selection should allow export")
        expect(selected.selectionTitle == "已选 2 / 3 页", "selection title should include selected and total page counts")
        expect(
            selected.selectionTitle(emptyTitle: "选择考试页", includesTotal: false) == "已选 2 页",
            "selection title should support exam page selection copy"
        )
        expect(selected.navigationTitle(hasGeneratedImage: true) == "页面长图", "generated image should override selection title")

        let rendering = PDFPageExportSelectionSnapshot(pageCount: 3, selectedIndices: [0, 1, 2], isRendering: true)
        expect(rendering.allSelected, "full selection should report all selected")
        expect(!rendering.canExport, "rendering state should disable export")
    }

    private static func testPageIndexDisplayHelpers() {
        expect(
            PDFPageIndexDisplay.pageTitle(forZeroBasedIndex: 2) == "第 3 页",
            "page titles should convert zero-based indices to user-facing page numbers"
        )
        expect(
            PDFPageIndexDisplay.selectionAccessibilityLabel(
                zeroBasedIndex: 1,
                isSelected: true,
                supplementTitle: "已作答"
            ) == "第 2 页，已选择，已作答",
            "selection accessibility labels should reuse page titles and append supplements"
        )
        expect(
            PDFPageIndexDisplay.parseStoredIndices("0, 2, bad,4") == [0, 2, 4],
            "stored page index parsing should ignore invalid tokens"
        )
        expect(
            PDFPageIndexDisplay.serializeStoredIndices([0, 2, 4]) == "0,2,4",
            "stored page index serialization should use comma-separated zero-based indices"
        )
        expect(
            PDFPageIndexDisplay.userPageNumbers(forZeroBasedIndices: [0, 2, 4]) == [1, 3, 5],
            "user page numbers should convert every zero-based index"
        )
        expect(
            PDFPageIndexDisplay.summary([1, 2, 3], limit: 2) == "1、2...",
            "page summaries should support explicit display limits"
        )
        expect(
            PDFPageIndexDisplay.summary([]) == "无页面",
            "empty page summaries should be explicit"
        )
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError(message, file: file, line: line)
        }
    }
}
