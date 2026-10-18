import Foundation

extension DiaryEntryDetailPane {
    // MARK: Actions

    @discardableResult
    func saveDiaryChanges(alertTitle: String) -> Bool {
        do {
            try modelContext.saveOrRollbackIfNeeded()
            return true
        } catch {
            alert = AppAlert(title: alertTitle, error: error)
            return false
        }
    }

    func confirmAllDrafts() {
        let now = Date()
        var didChange = false
        for item in entry.items where item.status == "draft" {
            item.status = "confirmed"
            item.updatedAt = now
            didChange = true
        }
        if didChange {
            guard saveDiaryChanges(alertTitle: "无法保存知识点") else { return }
        }
        phase = .readOnly
    }

    func saveEdits() {
        guard editContent.differs(from: entry) else {
            phase = .readOnly
            return
        }

        let knowledgeContentChanged = editContent.knowledgeContentDiffers(from: entry)

        editContent.apply(to: entry)
        entry.updatedAt = .now

        if knowledgeContentChanged {
            for item in entry.items {
                modelContext.delete(item)
            }
        }

        guard saveDiaryChanges(alertTitle: "无法保存日记") else { return }
        phase = .readOnly
    }

    func deleteEntry() {
        modelContext.delete(entry)
        guard saveDiaryChanges(alertTitle: "无法删除日记") else { return }
        onDelete()
    }

    func deleteKnowledgeItems(where shouldDelete: (KnowledgeItem) -> Bool) -> Bool {
        var didDelete = false
        for item in entry.items where shouldDelete(item) {
            modelContext.delete(item)
            didDelete = true
        }
        return didDelete
    }

}
