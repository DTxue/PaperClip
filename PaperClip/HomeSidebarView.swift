import SwiftUI

enum HomeSidebarTab: String {
    case diary, knowledge
}

struct HomeSidebarView: View {
    @Binding var sidebarTab: HomeSidebarTab
    @Binding var selection: DiaryListItem?
    @Binding var selectedSubject: String
    @Binding var newEntryDate: Date?
    @Binding var alert: AppAlert?

    let diaryAIModelRaw: String
    let knowledgeSnapshot: HomeKnowledgeSnapshot
    let onDateSelected: (Date, UUID?) -> Void

    var body: some View {
        List(selection: $selection) {
            Section {
                Picker("内容", selection: $sidebarTab) {
                    Text("日记").tag(HomeSidebarTab.diary)
                    Text("知识库").tag(HomeSidebarTab.knowledge)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            if sidebarTab == .diary {
                Section {
                    DiaryCalendarView(
                        selection: selection,
                        newEntryDate: newEntryDate,
                        alert: $alert,
                        onSelectDate: onDateSelected
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
                    .listRowSeparator(.hidden)
                }
            } else {
                HomeKnowledgeSidebarRows(
                    snapshot: knowledgeSnapshot,
                    selectedSubject: $selectedSubject
                )
            }
        }
        .listStyle(.sidebar)
        .paperClipSidebarColumn(sidebarTitle)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    if sidebarTab == .diary {
                        Image(diaryModelIconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    Text(sidebarTitle)
                        .font(.headline)
                }
            }
        }
    }

    private var sidebarTitle: String {
        sidebarTab == .diary ? "日记" : "知识库"
    }

    private var diaryModelIconName: String {
        let model = AIAnswerModel(rawValue: diaryAIModelRaw) ?? .doubao
        return model == .doubao ? "doubao-icon" : "deepseek-icon"
    }
}
