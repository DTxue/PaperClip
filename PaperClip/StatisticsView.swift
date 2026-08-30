import SwiftUI
import SwiftData

enum StatisticsSection: String, CaseIterable, Identifiable {
    case vocabulary = "今日 ENG 统计"
    case pdfExam = "今日 PDF 考试统计"

    var id: Self { self }

    var icon: String {
        switch self {
        case .vocabulary:
            return "character.book.closed"
        case .pdfExam:
            return "doc.richtext"
        }
    }
}

struct StatisticsView: View {
    let isActive: Bool

    @Environment(\.modelContext) private var modelContext
    @State private var snapshot = StatisticsSnapshot.empty
    @State private var selection: StatisticsSection? = .vocabulary
    @State var selectedPDFExamRow: StatisticsPDFExamRow?
    @State private var alert: AppAlert?

    init(isActive: Bool = true) {
        self.isActive = isActive
    }

    var body: some View {
        PaperClipNavigationSplitView {
            StatisticsSidebarView(selection: $selection)
        } detail: {
            statisticsDetail
        }
        .onAppear {
            refreshSnapshotIfActive()
        }
        .task(id: isActive) {
            refreshSnapshotIfActive()
        }
        .fullScreenCover(item: $selectedPDFExamRow) { row in
            PDFDocumentLoader(documentID: row.sourceDocumentID) { document in
                PDFWorkspaceView(document: document, initialAttemptID: row.id)
            }
        }
        .appAlert($alert)
    }

    @ViewBuilder
    private var statisticsDetail: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(alignment: .leading, spacing: 12) {
                switch selection {
                case .vocabulary:
                    vocabularySummaryCard(snapshot.vocabularySummary)
                case .pdfExam:
                    pdfExamSummaryCard(snapshot.pdfExamSummary)
                case nil:
                    ContentUnavailableView("请选择统计项", systemImage: "chart.bar")
                }
            }
            .frame(maxWidth: 980, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.visible)
        .navigationTitle(selection?.rawValue ?? "学习统计")
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

struct StatisticsSidebarView: View {
    @Binding var selection: StatisticsSection?

    var body: some View {
        List(StatisticsSection.allCases, selection: $selection) { section in
            Label(section.rawValue, systemImage: section.icon)
                .tag(section)
        }
        .listStyle(.sidebar)
        .paperClipSidebarColumn("统计")
    }
}
