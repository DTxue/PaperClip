import SwiftUI
import SwiftData

struct StatisticsView: View {
    let isActive: Bool

    @Environment(\.modelContext) private var modelContext
    @State private var snapshot = StatisticsSnapshot.empty
    @State private var alert: AppAlert?

    init(isActive: Bool = true) {
        self.isActive = isActive
    }

    var body: some View {
        statisticsDetail
        .onAppear {
            refreshSnapshotIfActive()
        }
        .task(id: isActive) {
            refreshSnapshotIfActive()
        }
        .appAlert($alert)
    }

    @ViewBuilder
    private var statisticsDetail: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(alignment: .leading, spacing: 12) {
                vocabularySummaryCard(snapshot.vocabularySummary)
            }
            .frame(maxWidth: 980, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.visible)
        .navigationTitle("今日英语统计")
        .navigationBarTitleDisplayMode(.large)
    }

    private func refreshSnapshotIfActive() {
        guard isActive else { return }
        refreshSnapshot()
    }

    private func refreshSnapshot() {
        do {
            snapshot = try StatisticsSnapshot.load(modelContext: modelContext)
        } catch {
            alert = AppAlert(title: "无法读取学习统计", error: error)
        }
    }
}
