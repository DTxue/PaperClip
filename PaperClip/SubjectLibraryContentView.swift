import SwiftUI

struct SubjectLibraryContentView: View {
    let snapshot: SubjectLibrarySnapshot
    let importPDF: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if snapshot.masterySummary.total > 0 {
                    SubjectLibraryDashboard(snapshot: snapshot)
                        .padding(.bottom, 8)
                }
                if snapshot.visibleSubjects.isEmpty {
                    emptyState
                } else {
                    subjectGrid
                }
            }
            .frame(maxWidth: 1_200, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("还没有题目", systemImage: "books.vertical")
        } description: {
            Text("点击右上角 + 导入一份 PDF，或在「设置 → 学习设置」中开启常用学科。")
        } actions: {
            Button("导入 PDF", systemImage: "plus", action: importPDF)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
    }

    private var subjectGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 180), spacing: 16)],
            spacing: 16
        ) {
            ForEach(snapshot.subjectCards) { card in
                NavigationLink {
                    SubjectDetailView(subject: card.subject.rawValue)
                } label: {
                    SubjectLibraryCard(
                        title: card.title,
                        icon: card.icon,
                        paperCount: card.paperCount,
                        mistakeCount: card.mistakeCount
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: 980)
    }
}
