import SwiftData
import SwiftUI

extension VocabularyCardSplitView {
    func startLoad() {
        cancelSplitTask()
        isLoading = true
        errorMessage = nil
        _ = splitTaskSlot.start { taskID in
            await loadSplits(taskID: taskID)
            splitTaskSlot.finish(taskID)
        }
    }

    @MainActor
    func loadSplits(taskID: UUID) async {
        do {
            let result = try await AIService.splitCard(term: card.term, definition: card.definition)
            try Task.checkCancellation()
            guard splitTaskSlot.isCurrent(taskID) else { return }
            splits = result.cards
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled,
                  splitTaskSlot.isCurrent(taskID) else { return }
            errorMessage = error.localizedDescription
        }
        guard splitTaskSlot.isCurrent(taskID) else { return }
        isLoading = false
    }

    func cancelSplitTask() {
        splitTaskSlot.cancel()
        isLoading = false
    }

    func confirmSplit() {
        cancelSplitTask()
        for split in splits {
            modelContext.insert(VocabularyCard(
                deckID: deck.id,
                term: split.term,
                definition: split.definition,
                phonetic: card.phonetic,
                example: card.example,
                partOfSpeech: card.partOfSpeech,
                tagsText: card.tagsText,
                note: card.note,
                alternativeAnswersText: card.alternativeAnswersText
            ))
        }
        modelContext.delete(card)
        deck.updatedAt = .now
        do {
            try modelContext.saveOrRollbackIfNeeded()
            dismiss()
        } catch {
            alert = AppAlert(title: "无法保存拆分结果", error: error)
        }
    }
}
