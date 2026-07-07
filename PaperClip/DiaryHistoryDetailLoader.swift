import SwiftData
import SwiftUI

struct DiaryHistoryDetailLoader: View {
    @Environment(\.modelContext) private var modelContext
    let entryID: UUID
    @State private var entry: DiaryEntry?
    @State private var alert: AppAlert?

    var body: some View {
        Group {
            if let entry {
                DiaryDetailView(entry: entry)
            } else {
                ProgressView()
                    .navigationTitle("日记详情")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .task(id: entryID) {
            loadEntry()
        }
        .appAlert($alert)
    }

    private func loadEntry() {
        do {
            entry = try modelContext.fetchDiaryEntry(id: entryID)
        } catch {
            entry = nil
            alert = AppAlert(title: "无法读取日记详情", error: error)
        }
    }
}
