import SwiftData
import SwiftUI

extension VocabularyFlashcardView {
    func finishRound() {
        if nextRound.isEmpty {
            sessionFinished = true
            recordSessionIfNeeded(kind: "闪卡")
        } else {
            do {
                try VocabularyStudySessionTransaction.saveProgress(in: modelContext)
                roundFinished = true
            } catch {
                alert = AppAlert(title: "无法保存学习进度", error: error)
            }
        }
    }

    func recordSessionIfNeeded(kind: String) {
        guard !didRecordSession else { return }
        do {
            didRecordSession = try VocabularyStudySessionTransaction.recordSession(
            deckID: deck.id,
            kind: kind,
            startedAt: sessionStartedAt,
            items: sessionItems,
            in: modelContext
        )
        } catch {
            alert = AppAlert(title: "无法保存学习记录", error: error)
        }
    }

    func startNextRound() {
        queue = nextRound
        nextRound = []
        index = 0
        round += 1
        roundKnownCount = 0
        roundLearningCount = 0
        roundFinished = false
        isRevealed = false
        swipeOffset = .zero
        cardEntryOffset = 0
        cardEntryOpacity = 1
        startedAt = .now
    }
}
