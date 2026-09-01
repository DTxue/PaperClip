import Foundation

@main
struct StoredFileTests {
    static func main() {
        assertPath(
            StoredFile.mistakeAttachment(fileName: "question.heic").url,
            suffix: "/MistakeAttachments/question.heic"
        )
        print("StoredFileTests: passed")
    }

    private static func assertPath(_ url: URL, suffix: String) {
        precondition(
            url.path.hasSuffix(suffix),
            "Expected \(url.path) to end with \(suffix)"
        )
    }
}
