import Foundation

extension VocabularyStudyView {
    func check(_ card: VocabularyCard) {
        let placed = placedTileIDs.compactMap { id in
            wordBankTiles.first { $0.id == id }?.text
        }
        isCorrect = placed == correctTiles
        hasChecked = true
    }

    func advance(_ card: VocabularyCard) {
        let placed = placedTileIDs.compactMap { id in
            wordBankTiles.first { $0.id == id }?.text
        }
        sessionItems.append(
            VocabularyStudySessionItemFactory.makeWordBankAnswer(
                card: card,
                placedWords: placed,
                isCorrect: isCorrect
            )
        )
        do {
            try VocabularyMemoryScheduler.record(
                card: card,
                deck: deck,
                direction: .definitionToTerm,
                rating: isCorrect ? .good : .again,
                responseKind: "拼句",
                duration: Date.now.timeIntervalSince(startedAt),
                modelContext: modelContext,
                saveImmediately: false
            )
        } catch {
            modelContext.rollback()
            alert = AppAlert(title: "无法记录学习结果", error: error)
            return
        }
        index += 1
        if index >= queue.count {
            recordSessionIfNeeded()
        }
    }

    func recordSessionIfNeeded() {
        guard !didRecordSession else { return }
        do {
            didRecordSession = try VocabularyStudySessionTransaction.recordSession(
            deckID: deck.id,
            kind: "学习",
            startedAt: sessionStartedAt,
            items: sessionItems,
            in: modelContext
        )
        } catch {
            alert = AppAlert(title: "无法保存学习记录", error: error)
        }
    }
}
