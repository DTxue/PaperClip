import SwiftUI

struct PaperCardSelectionList: View {
    let availableCards: [MistakeCardRowData]
    let snapshot: PaperSelectionSnapshot
    @Binding var filterStatus: PaperSelectionStatusFilter
    @Binding var selectedIDs: Set<UUID>

    var body: some View {
        List {
            Section {
                Picker("范围", selection: $filterStatus) {
                    ForEach(PaperSelectionStatusFilter.allCases) { filter in
                        Text(filter.label).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: filterStatus) {
                    selectedIDs = PaperSelectionSnapshot.selectedIDs(
                        from: availableCards,
                        filterStatus: filterStatus
                    )
                }
            } header: {
                Text("选择题目范围")
            } footer: {
                if selectedIDs.isEmpty {
                    Text("请至少选择 1 道题目。")
                } else {
                    Text("已选 \(selectedIDs.count) 道题。点击题目可单独取消。")
                }
            }

            Section {
                ForEach(snapshot.displayCards) { card in
                    let isSelected = selectedIDs.contains(card.id)
                    PaperCardSelectionRow(card: card, isSelected: isSelected) {
                        if isSelected {
                            selectedIDs.remove(card.id)
                        } else {
                            selectedIDs.insert(card.id)
                        }
                    }
                }
            }
        }
    }
}
