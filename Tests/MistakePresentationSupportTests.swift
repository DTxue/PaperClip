import Foundation

@main
enum MistakePresentationSupportTests {
    static func main() {
        expect(
            MistakeScannerAccessPolicy.action(for: .notDetermined) == .requestAccess,
            "first scan requests camera access before presenting VisionKit"
        )
        expect(
            MistakeScannerAccessPolicy.action(for: .authorized) == .presentScanner,
            "authorized camera presents scanner immediately"
        )
        expect(
            MistakeScannerAccessPolicy.action(for: .denied) == .showPermissionError,
            "denied camera reports permission error"
        )

        let html = MistakeQuestionHTML.document(for: "已知 $x < 2$\n求 $x^2$。")
        expect(html.contains("href=\"katex.min.css\""), "formula document loads bundled KaTeX styles")
        expect(html.contains("src=\"katex.min.js\""), "formula document loads bundled KaTeX script")
        expect(!html.contains("https://"), "formula document never loads remote resources")
        expect(html.contains("Content-Security-Policy"), "formula document restricts resource origins")
        expect(html.contains("$x &lt; 2$"), "question HTML escapes source text")
        expect(html.contains("<br>"), "question HTML preserves line breaks")
        expect(html.contains("prefers-color-scheme: dark"), "formula document supports dark mode")
        expect(html.contains("paperClipMistakeHeight"), "formula document reports rendered height")
        expect(MistakeQuestionHTML.containsFormula(in: "求 $x^2$"), "detects inline formulas")
        expect(!MistakeQuestionHTML.containsFormula(in: "普通文字题目"), "plain text avoids a WebView")

        print("MistakePresentationSupportTests: 13 passed")
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
