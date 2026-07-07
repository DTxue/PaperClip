import SwiftUI

struct HomeKnowledgeSidebarRows: View {
    let snapshot: HomeKnowledgeSnapshot
    @Binding var selectedSubject: String

    var body: some View {
        knowledgeSidebarRow(label: "全部", icon: "tray.full", value: "")
        if !snapshot.subjects.isEmpty {
            Section("学科") {
                ForEach(snapshot.subjects, id: \.self) { subject in
                    knowledgeSidebarRow(label: subject, icon: "folder", value: subject)
                }
            }
        }
    }

    private func knowledgeSidebarRow(label: String, icon: String, value: String) -> some View {
        let isActive = selectedSubject == value
        return SidebarFilterRow(label: label, systemImage: icon, isActive: isActive) {
            selectedSubject = value
        }
    }
}

struct HomeKnowledgeDetailView: View {
    let snapshot: HomeKnowledgeSnapshot
    let selectedSubject: String
    @Binding var selectedKnowledgeItem: KnowledgeItemListRowData?

    var body: some View {
        Group {
            if snapshot.visibleItems.isEmpty {
                ContentUnavailableView(
                    "还没有知识点",
                    systemImage: "brain",
                    description: Text("在日记中整理知识点并确认后，将在这里显示。")
                )
            } else {
                List {
                    ForEach(snapshot.visibleItems) { item in
                        Button { selectedKnowledgeItem = item } label: {
                            KnowledgeItemListRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle(selectedSubject.isEmpty ? "全部知识点" : selectedSubject)
    }
}
