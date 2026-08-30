extension VocabularyFlashcardView {
    func finishRound() {
        if nextRound.isEmpty {
            sessionFinished = true
        } else {
            roundFinished = true
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
    }
}
