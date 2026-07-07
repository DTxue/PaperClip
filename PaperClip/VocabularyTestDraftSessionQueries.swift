extension VocabularyTestView {
    func refreshLatestDraft() {
        let deckID = deck.id
        do {
            latestDraft = try modelContext.fetchLatestVocabularyTestDraft(
                deckID: deckID,
                mode: VocabularyTestMode.exam.rawValue
            )
        } catch {
            latestDraft = nil
            alert = AppAlert(title: "无法读取考试草稿", error: error)
        }
    }

    func deleteDraft(_ draft: VocabularyTestDraft) {
        modelContext.delete(draft)
        do {
            try modelContext.saveOrRollbackIfNeeded()
            if latestDraft?.id == draft.id {
                latestDraft = nil
            }
            refreshLatestDraft()
        } catch {
            refreshLatestDraft()
            alert = AppAlert(title: "无法删除考试草稿", error: error)
        }
    }

    @discardableResult
    func deleteExamDraft() -> Bool {
        let deckID = deck.id
        do {
            let deletedCount = try modelContext.deleteVocabularyTestDrafts(
                deckID: deckID,
                mode: VocabularyTestMode.exam.rawValue
            )
            guard deletedCount > 0 else { return false }
            latestDraft = nil
            return true
        } catch {
            modelContext.rollback()
            alert = AppAlert(title: "无法删除考试草稿", error: error)
            refreshLatestDraft()
            return false
        }
    }
}
