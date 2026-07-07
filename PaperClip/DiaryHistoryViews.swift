import SwiftData
import SwiftUI

struct DiaryHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var entries: [DiaryHistoryRowData] = []
    @State private var alert: AppAlert?

    private let entryLimit = 365

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "还没有日记",
                    systemImage: "note.text",
                    description: Text("从首页开始写下你的第一篇日记。")
                )
            } else {
                List {
                    Section("最近 \(entryLimit) 篇") {
                        ForEach(entries) { entry in
                            NavigationLink {
                                DiaryHistoryDetailLoader(entryID: entry.id)
                            } label: {
                                DiaryHistoryRow(entry: entry)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("日记历史")
        .task {
            fetchRecentEntries()
        }
        .appAlert($alert)
    }

    private func fetchRecentEntries() {
        do {
            entries = try modelContext.fetchRecentDiaryEntries(
                limit: entryLimit,
                propertiesToFetch: DiaryHistoryRowData.propertiesToFetch
            ).map(DiaryHistoryRowData.init)
        } catch {
            alert = AppAlert(title: "无法读取日记历史", error: error)
            entries = []
        }
    }
}
