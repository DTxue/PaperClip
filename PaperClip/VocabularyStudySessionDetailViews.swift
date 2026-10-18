import SwiftUI
import SwiftData

struct VocabularyStudySessionDetailLoader: View {
    @Environment(\.modelContext) private var modelContext
    let sessionID: UUID
    let onDismiss: () -> Void

    @State private var session: VocabularyStudySession?
    @State private var alert: AppAlert?

    var body: some View {
        NavigationStack {
            Group {
                if let session {
                    VocabularyStudySessionDetailView(session: session)
                } else {
                    ProgressView()
                        .navigationTitle("成绩详情")
                }
            }
            .doneToolbar(action: onDismiss)
        }
        .task(id: sessionID) {
            loadSession()
        }
        .appAlert($alert)
    }

    private func loadSession() {
        do {
            session = try modelContext.fetchVocabularyStudySession(id: sessionID)
        } catch {
            session = nil
            alert = AppAlert(title: "无法读取成绩详情", error: error)
        }
    }
}

private struct VocabularyStudySessionDetailView: View {
    let session: VocabularyStudySession

    var body: some View {
        let snapshot = VocabularyStudySessionDetailSnapshot(session: session)
        let isEnglishDefinitionHandwriting = session.kind == "英文释义手写"

        List {
            Section("本次记录") {
                LabeledContent("模式", value: session.kind)
                if let selectionDescription = session.testSelectionDescription {
                    LabeledContent("选题范围", value: selectionDescription)
                }
                LabeledContent("时间") {
                    Text(session.endedAt, format: .dateTime.year().month().day().hour().minute())
                }
                LabeledContent("学习时长", value: VocabularyStudySessionFormat.duration(session.duration))
                LabeledContent("错误率", value: VocabularyStudySessionFormat.percent(session.errorRate))
                LabeledContent("错误题数", value: "\(snapshot.incorrectItems.count) / \(session.totalCount)")
            }

            Section("错误列表") {
                if snapshot.incorrectItems.isEmpty {
                    ContentUnavailableView("没有错题", systemImage: "checkmark.circle")
                } else {
                    ForEach(snapshot.incorrectItems.indices, id: \.self) { index in
                        let item = snapshot.incorrectItems[index]
                        VocabularyStudySessionItemRow(
                            item: item,
                            showsRecognizedText: session.kind == "测验"
                                || session.kind == "语境练习"
                                || isEnglishDefinitionHandwriting
                        )
                    }
                }
            }

            Section("正确列表") {
                if snapshot.correctItems.isEmpty {
                    ContentUnavailableView("没有正确题目", systemImage: "xmark.circle")
                } else {
                    ForEach(snapshot.correctItems.indices, id: \.self) { index in
                        let item = snapshot.correctItems[index]
                        VocabularyStudySessionItemRow(
                            item: item,
                            showsRecognizedText: isEnglishDefinitionHandwriting
                        )
                    }
                }
            }
        }
        .navigationTitle("成绩详情")
    }
}
