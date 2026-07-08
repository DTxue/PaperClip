import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var snapshot = StatisticsSnapshot.empty
    @State private var alert: AppAlert?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if !snapshot.hasAnyData {
                    ContentUnavailableView(
                        "暂无数据",
                        systemImage: "chart.bar",
                        description: Text("完成做题、收录错题或使用刷子后，这里会显示学习进度分析。")
                    )
                    .frame(maxWidth: .infinity, minHeight: 420)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 20)], spacing: 20) {
                        vocabularySummaryCard(snapshot.vocabularySummary)
                        pdfExamSummaryCard(snapshot.pdfExamSummary)
                        weakPointsCard(snapshot.topTags)
                        practiceActivityCard(snapshot.practiceWeekData)
                    }
                }
            }
            .frame(maxWidth: 1_400, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .paperClipThemedSurface(.page)
        .navigationTitle("学习统计")
        .navigationBarTitleDisplayMode(.large)
        .task {
            refreshSnapshot()
        }
        .appAlert($alert)
    }

    private func refreshSnapshot() {
        do {
            snapshot = try StatisticsSnapshot.load(modelContext: modelContext)
        } catch {
            alert = AppAlert(title: "无法读取学习统计", error: error)
        }
    }
}
