import CoreGraphics
import Foundation

@main
struct PDFLongImageLayoutSupportTests {
    static func main() {
        testConstrainedWidthUsesPixelLimit()
        testConstrainedWidthRejectsTooSmallOutput()
        testOutputSizePreservesPageAspectRatio()
        testPageLayoutsFilterInvalidPagesAndPreserveOrder()
        testStackedLayoutBuildsDestinationsWithoutGaps()
        testStackedLayoutAppliesGapsAndRoundedHeights()
        testConstrainedStackLayoutBuildsScaledStack()
        testStackedLayoutRejectsInvalidInputs()
        testDrawingImageScaleMatchesOutputPixels()
        print("PDFLongImageLayoutSupportTests: 9 passed")
    }

    private static func testConstrainedWidthUsesPixelLimit() {
        let width = PDFLongImageLayoutSupport.constrainedWidth(
            preferredWidth: 1_500,
            minimumWidth: 600,
            maximumHeight: 24_000,
            maximumPixelCount: 9_000_000,
            totalAspectRatio: 9
        )
        expect(width == 1_000, "width should be constrained by max pixel count")
    }

    private static func testConstrainedWidthRejectsTooSmallOutput() {
        let width = PDFLongImageLayoutSupport.constrainedWidth(
            preferredWidth: 1_500,
            minimumWidth: 600,
            maximumHeight: 1_000,
            maximumPixelCount: 1_000_000,
            totalAspectRatio: 4
        )
        expect(width == nil, "width below minimum should be rejected")
    }

    private static func testPageLayoutsFilterInvalidPagesAndPreserveOrder() {
        let layouts = PDFLongImageLayoutSupport.pageLayouts(
            pageInputs: [
                (index: 2, sourceSize: CGSize(width: 200, height: 100)),
                (index: 3, sourceSize: .zero),
                (index: 4, sourceSize: CGSize(width: 100, height: 300))
            ],
            outputWidth: 600
        )

        expect(layouts.map(\.index) == [2, 4], "valid page order should be preserved")
        expect(layouts[0].outputSize == CGSize(width: 600, height: 300), "landscape page height")
        expect(layouts[1].outputSize == CGSize(width: 600, height: 1_800), "portrait page height")
        expect(PDFLongImageLayoutSupport.totalAspectRatio(layouts) == 3.5, "total aspect ratio")
        expect(
            PDFLongImageLayoutSupport.totalAspectRatio(pageInputs: [
                (index: 2, sourceSize: CGSize(width: 200, height: 100)),
                (index: 3, sourceSize: .zero),
                (index: 4, sourceSize: CGSize(width: 100, height: 300))
            ]) == 3.5,
            "input aspect ratio should filter invalid pages"
        )
    }

    private static func testOutputSizePreservesPageAspectRatio() {
        let size = PDFLongImageLayoutSupport.outputSize(
            sourceSize: CGSize(width: 700, height: 990),
            outputWidth: 1_400
        )

        expect(size == CGSize(width: 1_400, height: 1_980), "output size should preserve source aspect ratio")
        expect(
            PDFLongImageLayoutSupport.outputSize(sourceSize: .zero, outputWidth: 1_400) == nil,
            "invalid source size should be rejected"
        )
        expect(
            PDFLongImageLayoutSupport.outputSize(sourceSize: CGSize(width: 700, height: 990), outputWidth: 0) == nil,
            "invalid output width should be rejected"
        )
    }

    private static func testDrawingImageScaleMatchesOutputPixels() {
        expect(
            PDFLongImageLayoutSupport.drawingImageScale(outputPixelWidth: 1_500, canvasWidth: 750) == 2,
            "drawing scale should map canvas width to output pixels"
        )
        expect(
            PDFLongImageLayoutSupport.drawingImageScale(outputPixelWidth: 1_400, canvasWidth: 560) == 2.5,
            "drawing scale should not be hard-coded to 2"
        )
        expect(
            PDFLongImageLayoutSupport.drawingImageScale(outputPixelWidth: 0, canvasWidth: 750) == 1,
            "invalid output width should fall back to 1"
        )
        expect(
            PDFLongImageLayoutSupport.drawingImageScale(outputPixelWidth: 1_500, canvasWidth: 0) == 1,
            "invalid canvas width should fall back to 1"
        )
    }

    private static func testStackedLayoutBuildsDestinationsWithoutGaps() {
        let layout = PDFLongImageLayoutSupport.stackedLayout(
            pageInputs: [
                (index: 0, sourceSize: CGSize(width: 200, height: 100)),
                (index: 1, sourceSize: CGSize(width: 100, height: 300))
            ],
            outputWidth: 600
        )

        expect(layout != nil, "valid pages should produce a stacked layout")
        expect(layout!.outputSize == CGSize(width: 600, height: 2_100), "total output size should sum page heights")
        expect(
            layout!.pages.map(\.destination) == [
                CGRect(x: 0, y: 0, width: 600, height: 300),
                CGRect(x: 0, y: 300, width: 600, height: 1_800)
            ],
            "destinations should stack pages without a gap by default"
        )
    }

    private static func testStackedLayoutAppliesGapsAndRoundedHeights() {
        let layout = PDFLongImageLayoutSupport.stackedLayout(
            pageInputs: [
                (index: 0, sourceSize: CGSize(width: 3, height: 2)),
                (index: 1, sourceSize: CGSize(width: 4, height: 1))
            ],
            outputWidth: 10,
            pageGap: 2,
            roundsPageHeights: true
        )

        expect(layout != nil, "valid pages with gaps should produce a stacked layout")
        expect(layout!.pages[0].outputSize.height == 7, "first page height should be rounded up")
        expect(layout!.pages[1].destination == CGRect(x: 0, y: 9, width: 10, height: 3), "second page y should include gap")
        expect(layout!.outputSize == CGSize(width: 10, height: 12), "total height should include one gap")
    }

    private static func testConstrainedStackLayoutBuildsScaledStack() {
        let layout = PDFLongImageLayoutSupport.constrainedStackLayout(
            pageInputs: [
                (index: 0, sourceSize: CGSize(width: 100, height: 200)),
                (index: 1, sourceSize: CGSize(width: 100, height: 100))
            ],
            preferredPixelWidth: 1_000,
            minimumPixelWidth: 200,
            maximumPixelHeight: 10_000,
            maximumPixelCount: 10_000_000,
            outputScale: 2,
            pageGap: 4,
            roundsPageHeights: true
        )

        expect(layout != nil, "valid inputs should produce a constrained stack layout")
        expect(layout!.targetPixelWidth == 1_000, "target pixel width should be preserved for drawing scale")
        expect(layout!.stackLayout.outputSize == CGSize(width: 500, height: 1_504), "logical output size should honor scale and gap")
        expect(
            layout!.stackLayout.pages.map(\.destination) == [
                CGRect(x: 0, y: 0, width: 500, height: 1_000),
                CGRect(x: 0, y: 1_004, width: 500, height: 500)
            ],
            "page frames should be stacked at logical output scale"
        )
    }

    private static func testStackedLayoutRejectsInvalidInputs() {
        expect(
            PDFLongImageLayoutSupport.stackedLayout(
                pageInputs: [(index: 0, sourceSize: CGSize(width: 100, height: 100))],
                outputWidth: 0
            ) == nil,
            "invalid output width should be rejected"
        )
        expect(
            PDFLongImageLayoutSupport.stackedLayout(
                pageInputs: [(index: 0, sourceSize: CGSize(width: 100, height: 100))],
                outputWidth: 100,
                pageGap: -1
            ) == nil,
            "negative gaps should be rejected"
        )
        expect(
            PDFLongImageLayoutSupport.stackedLayout(
                pageInputs: [(index: 0, sourceSize: .zero)],
                outputWidth: 100
            ) == nil,
            "layouts with no valid pages should be rejected"
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
