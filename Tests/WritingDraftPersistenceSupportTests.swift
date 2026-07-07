import CoreGraphics
import Foundation

@main
struct WritingDraftPersistenceSupportTests {
    static func main() {
        testBlankDraftWithTinyGeometryDriftIsNotCreated()
        testTinyGeometryDriftDoesNotDirtyExistingDraft()
        testMeaningfulGeometryChangeStillApplies()
        testFullscreenViewportExpandsNarrowPaper()
        testFullscreenViewportDoesNotShrinkPaper()
        print("WritingDraftPersistenceSupportTests: 5 passed")
    }

    private static func testBlankDraftWithTinyGeometryDriftIsNotCreated() {
        let payload = WritingDraftSavePayload(
            paperStyle: .lined,
            blackPaperMode: false,
            paperSize: CGSize(width: WritingPaperMetrics.defaultWidth + 0.25, height: WritingPaperMetrics.defaultHeight - 0.25),
            rulingSpacing: WritingPaperMetrics.defaultLineSpacing + 0.25,
            reviewStatus: .draft,
            drawingData: Data(),
            hasInk: false
        )

        expect(!payload.shouldCreateDraft, "tiny default geometry drift should not create an empty draft")
    }

    private static func testTinyGeometryDriftDoesNotDirtyExistingDraft() {
        let draft = WritingDraft(
            promptID: UUID(),
            language: .chinese,
            paperWidth: WritingPaperMetrics.defaultWidth,
            paperHeight: WritingPaperMetrics.defaultHeight,
            rulingSpacing: WritingPaperMetrics.defaultLineSpacing
        )
        let payload = WritingDraftSavePayload(
            paperStyle: .lined,
            blackPaperMode: false,
            paperSize: CGSize(width: WritingPaperMetrics.defaultWidth + 0.25, height: WritingPaperMetrics.defaultHeight + 0.25),
            rulingSpacing: WritingPaperMetrics.defaultLineSpacing + 0.25,
            reviewStatus: .draft,
            drawingData: Data(),
            hasInk: false
        )

        expect(!draft.apply(payload), "tiny geometry drift should not dirty an existing draft")
    }

    private static func testMeaningfulGeometryChangeStillApplies() {
        let draft = WritingDraft(
            promptID: UUID(),
            language: .chinese,
            paperWidth: WritingPaperMetrics.defaultWidth,
            paperHeight: WritingPaperMetrics.defaultHeight,
            rulingSpacing: WritingPaperMetrics.defaultLineSpacing
        )
        let payload = WritingDraftSavePayload(
            paperStyle: .lined,
            blackPaperMode: false,
            paperSize: CGSize(width: WritingPaperMetrics.defaultWidth + 20, height: WritingPaperMetrics.defaultHeight),
            rulingSpacing: WritingPaperMetrics.defaultLineSpacing,
            reviewStatus: .draft,
            drawingData: Data(),
            hasInk: false
        )

        expect(draft.apply(payload), "meaningful geometry changes should still be applied")
        expect(Double(draft.paperSize.width) == WritingPaperMetrics.defaultWidth + 20, "draft width should update")
    }

    private static func testFullscreenViewportExpandsNarrowPaper() {
        let expandedWidth = WritingFullscreenPaperViewport.expandedPaperWidth(
            currentWidth: WritingPaperMetrics.minWidth,
            visibleWidth: 900
        )

        expect(expandedWidth == 868, "fullscreen viewport should expand paper to visible width minus padding")
    }

    private static func testFullscreenViewportDoesNotShrinkPaper() {
        let expandedWidth = WritingFullscreenPaperViewport.expandedPaperWidth(
            currentWidth: 900,
            visibleWidth: 700
        )

        expect(expandedWidth == nil, "fullscreen viewport should never shrink an existing paper width")
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
