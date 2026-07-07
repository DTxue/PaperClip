import SwiftUI

struct DiaryTextEditorSection: View {
    let icon: String
    let color: Color
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        Section {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .frame(minHeight: 80)
            }
        } header: {
            Label(title, systemImage: icon)
                .foregroundStyle(color)
        }
    }
}

struct DiaryEntryEditorSections: View {
    @Binding var content: DiaryEntryEditableContent

    var body: some View {
        DiaryTextEditorSection(
            icon: "book.fill", color: .blue,
            title: "今天学了什么",
            placeholder: "今天学了什么？",
            text: $content.learned
        )
        DiaryTextEditorSection(
            icon: "questionmark.circle.fill", color: .orange,
            title: "今天哪些地方没搞懂",
            placeholder: "有什么不明白的地方？",
            text: $content.confused
        )
        DiaryTextEditorSection(
            icon: "note.text", color: .purple,
            title: "今天有什么值得记录的",
            placeholder: "随便写，不用整理…",
            text: $content.noted
        )
        DiaryTextEditorSection(
            icon: "lightbulb.fill", color: .yellow,
            title: "今天有什么灵光一闪的想法",
            placeholder: "突然想到什么？",
            text: $content.inspired
        )
    }
}
