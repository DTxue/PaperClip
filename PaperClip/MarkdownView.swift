import SwiftUI

struct MarkdownView: View {
    let text: String
    private let attributedText: AttributedString

    init(text: String) {
        self.text = text
        self.attributedText = Self.parse(text)
    }

    var body: some View {
        Text(attributedText)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private static func parse(_ text: String) -> AttributedString {
        let normalized = text.replacingOccurrences(of: "\\n", with: "\n")
        if let attributed = try? AttributedString(
            markdown: normalized,
            options: .init(interpretedSyntax: .full)
        ) {
            return attributed
        }
        return AttributedString(normalized)
    }
}
