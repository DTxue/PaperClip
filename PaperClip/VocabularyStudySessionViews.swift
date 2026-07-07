import SwiftUI
import SwiftData

struct VocabularyStudySessionsView: View {
    let deck: VocabularyDeck

    @Environment(\.modelContext) private var modelContext
    @State private var sessions: [VocabularyStudySessionRowData] = []
    @State private var selectedSession: VocabularyStudySessionRowData?
    @State private var alert: AppAlert?

    private let sessionLimit = 100

    var body: some View {
        let snapshot = VocabularyStudySessionsSnapshot(sessions: sessions, limit: sessionLimit)

        Group {
            if snapshot.sessions.isEmpty {
                ContentUnavailableView(
                    "暂无成绩",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("完成学习或测验后，这里会显示每次学习的时长和正确率。")
                )
            } else {
                List {
                    Section("汇总") {
                        LabeledContent("统计范围", value: snapshot.scopeTitle)
                        LabeledContent("总时长", value: VocabularyStudySessionFormat.duration(snapshot.totalDuration))
                        LabeledContent("平均正确率", value: VocabularyStudySessionFormat.percent(snapshot.averageAccuracy))
                    }

                    Section("历史记录") {
                        ForEach(snapshot.sessions) { session in
                            Button {
                                selectedSession = session
                            } label: {
                                VocabularyStudySessionRowView(session: session)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .navigationTitle("成绩")
        .task {
            fetchRecentSessions()
        }
        .appAlert($alert)
        .sheet(item: $selectedSession) { session in
            VocabularyStudySessionDetailLoader(sessionID: session.id) {
                selectedSession = nil
            }
        }
    }

    private func fetchRecentSessions() {
        do {
            sessions = try modelContext.fetchVocabularyScoreSessions(
                deckID: deck.id,
                limit: sessionLimit,
                propertiesToFetch: VocabularyStudySessionRowData.propertiesToFetch
            ).map(VocabularyStudySessionRowData.init)
        } catch {
            alert = AppAlert(title: "无法读取成绩记录", error: error)
            sessions = []
        }
    }

}
