import Foundation

@main
struct StoredFileTests {
    static func main() {
        assertPath(StoredFile.importedPDF(fileName: "paper.pdf").url, suffix: "/PDFs/paper.pdf")
        assertPath(StoredFile.cardImage(fileName: "card.jpg").url, suffix: "/Cards/card.jpg")
        assertPath(StoredFile.examPDF(fileName: "exam.pdf").url, suffix: "/ExamPDFs/exam.pdf")
        assertPath(StoredFile.exportPDF(fileName: "export.pdf").url, suffix: "/Exports/export.pdf")
        print("StoredFileTests: 4 passed")
    }

    private static func assertPath(_ url: URL, suffix: String) {
        precondition(
            url.path.hasSuffix(suffix),
            "Expected \(url.path) to end with \(suffix)"
        )
    }
}
