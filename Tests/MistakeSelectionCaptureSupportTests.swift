import Foundation

@main
enum MistakeSelectionCaptureSupportTests {
    static func main() {
        testBuildsValidRequest()
        testRejectsInvalidRequest()

        print("MistakeSelectionCaptureSupportTests: 9 passed")
    }

    private static func testBuildsValidRequest() {
        let request = MistakeSelectionCaptureSupport.makeRequest(
            imageFileName: "card.jpg",
            originalWidth: 120,
            originalHeight: 80,
            sourceDocumentTitle: "代数试卷"
        )

        expect(request != nil, "valid capture should produce a request")
        expect(request?.imageFileName == "card.jpg", "file name should be preserved")
        expect(request?.originalWidth == 120, "width should be preserved")
        expect(request?.originalHeight == 80, "height should be preserved")
        expect(request?.sourceDocumentTitle == "代数试卷", "document title should be preserved")
    }

    private static func testRejectsInvalidRequest() {
        expect(
            MistakeSelectionCaptureSupport.makeRequest(
                imageFileName: "",
                originalWidth: 120,
                originalHeight: 80,
                sourceDocumentTitle: "试卷"
            ) == nil,
            "empty file name should be rejected"
        )
        expect(
            MistakeSelectionCaptureSupport.makeRequest(
                imageFileName: "card.jpg",
                originalWidth: 0,
                originalHeight: 80,
                sourceDocumentTitle: "试卷"
            ) == nil,
            "zero width should be rejected"
        )
        expect(
            MistakeSelectionCaptureSupport.makeRequest(
                imageFileName: "card.jpg",
                originalWidth: 120,
                originalHeight: -.infinity,
                sourceDocumentTitle: "试卷"
            ) == nil,
            "non-finite height should be rejected"
        )
        expect(
            MistakeSelectionCaptureRequest.isValidOriginalDimension(1),
            "positive finite dimension should be valid"
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
