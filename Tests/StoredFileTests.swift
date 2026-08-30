import Foundation

@main
struct StoredFileTests {
    static func main() {
        assertPath(StoredFile.importedPDF(fileName: "paper.pdf").url, suffix: "/PDFs/paper.pdf")
        assertPath(StoredFile.examPDF(fileName: "exam.pdf").url, suffix: "/ExamPDFs/exam.pdf")
        assertPath(
            StoredFile.mistakeAttachment(fileName: "question.heic").url,
            suffix: "/MistakeAttachments/question.heic"
        )
        print("StoredFileTests: 6 passed")
    }

    private static func assertPath(_ url: URL, suffix: String) {
        precondition(
            url.path.hasSuffix(suffix),
            "Expected \(url.path) to end with \(suffix)"
        )
    }
}
