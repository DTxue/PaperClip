import SwiftUI

struct DiaryEntryReadSections: View {
    let entry: DiaryEntry

    var body: some View {
        let contentPresence = entry.contentPresence
        if !contentPresence.hasAnyContent {
            ContentUnavailableView(
                "空白日记",
                systemImage: "note.text",
                description: Text("点击上方编辑，补充这天的记录。")
            )
        } else {
            if contentPresence.hasLearned {
                DiaryReadSection(
                    icon: "book.fill",
                    color: .blue,
                    title: "今天学了什么",
                    original: entry.learned
                )
            }
            if contentPresence.hasConfused {
                DiaryReadSection(
                    icon: "questionmark.circle.fill",
                    color: .orange,
                    title: "今天哪些地方没搞懂",
                    original: entry.confused
                )
            }
            if contentPresence.hasNoted {
                DiaryReadSection(
                    icon: "note.text",
                    color: .purple,
                    title: "今天有什么值得记录的",
                    original: entry.noted
                )
            }
            if contentPresence.hasInspired {
                DiaryReadSection(
                    icon: "lightbulb.fill",
                    color: .yellow,
                    title: "今天有什么灵光一闪的想法",
                    original: entry.inspired
                )
            }
        }
    }
}
