import Foundation

extension HomeView {
    var knowledgeSnapshot: HomeKnowledgeSnapshot {
        HomeKnowledgeSnapshot(
            items: knowledgeItems,
            selectedSubject: selectedSubject
        )
    }

    func refreshKnowledgeItems() {
        do {
            knowledgeItems = try modelContext.fetchConfirmedKnowledgeItems(
                propertiesToFetch: KnowledgeItemListRowData.propertiesToFetch
            ).map(KnowledgeItemListRowData.init)
        } catch {
            knowledgeItems = []
            alert = AppAlert(title: "无法读取知识库", error: error)
        }
    }

    func handleDateSelected(_ date: Date, entryID: UUID?) {
        switch HomeDiarySelectionDecision.decision(for: date, entryID: entryID) {
        case .today:
            selection = .today
            newEntryDate = nil
        case .existing(let entryID):
            guard let entry = fetchDiaryEntry(id: entryID) else { return }

            selection = .entry(entry)
            newEntryDate = nil
        case .new(let start):
            diaryDraft.reset()
            newEntryDate = start
            selection = nil
        }
    }

    private func fetchDiaryEntry(id: UUID) -> DiaryEntry? {
        do {
            return try modelContext.fetchDiaryEntry(id: id)
        } catch {
            alert = AppAlert(title: "无法读取日记", error: error)
            return nil
        }
    }
}
