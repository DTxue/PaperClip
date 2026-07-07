import SwiftData
import SwiftUI

enum DiaryListItem: Hashable {
    case today
    case entry(DiaryEntry)
}

struct HomeView: View {
    @Environment(\.modelContext) var modelContext

    @AppStorage("diaryAIModel") var diaryAIModelRaw = AIAnswerModel.doubao.rawValue

    @State var todayEntry: DiaryEntry?
    @State var knowledgeItems: [KnowledgeItemListRowData] = []
    @State var sidebarTab: HomeSidebarTab = .diary
    @State var selection: DiaryListItem? = .today
    @State var selectedSubject = ""
    @State var selectedKnowledgeItem: KnowledgeItemListRowData? = nil

    @State var diaryDraft = DiaryEntryEditableContent()
    @State var loadedDate: Date? = nil
    @State var newEntryDate: Date? = nil
    @State var alert: AppAlert?

    var body: some View {
        PaperClipNavigationSplitView {
            HomeSidebarView(
                sidebarTab: $sidebarTab,
                selection: $selection,
                selectedSubject: $selectedSubject,
                newEntryDate: $newEntryDate,
                alert: $alert,
                diaryAIModelRaw: diaryAIModelRaw,
                knowledgeSnapshot: knowledgeSnapshot,
                onDateSelected: handleDateSelected
            )
            .onChange(of: selection) { _, _ in newEntryDate = nil }
        } detail: {
            switch sidebarTab {
            case .diary:
                HomeDiaryDetailView(
                    todayEntry: $todayEntry,
                    selection: $selection,
                    diaryDraft: $diaryDraft,
                    loadedDate: $loadedDate,
                    newEntryDate: $newEntryDate,
                    alert: $alert
                )
            case .knowledge:
                HomeKnowledgeDetailView(
                    snapshot: knowledgeSnapshot,
                    selectedSubject: selectedSubject,
                    selectedKnowledgeItem: $selectedKnowledgeItem
                )
            }
        }
        .sheet(item: $selectedKnowledgeItem) { item in
            KnowledgeItemSheetLoader(itemID: item.id)
        }
        .appAlert($alert)
        .task(id: sidebarTab) {
            if sidebarTab == .knowledge {
                refreshKnowledgeItems()
            }
        }
    }
}
