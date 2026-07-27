import Foundation
import PencilKit

extension VocabularyTestView {
    func startTest() {
        fetchSessionData()
        guard selectedMode.canStart(cardCount: allCards.count) else {
            if alert == nil {
                if selectedMode == .debug {
                    alert = AppAlert(
                        title: "无法开始调试",
                        message: "调试模式需要至少 5 个单词。"
                    )
                } else {
                    alert = AppAlert(
                        title: "无法开始测验",
                        message: "词集中没有可用单词。"
                    )
                }
            }
            return
        }
        restartGradingSession()
        let recentLogs = fetchRecentReviewLogs(
            limit: VocabularyTestQuestionSelector.recentReviewLogLimit(cardCount: allCards.count)
        )
        let plan = VocabularyTestSessionPlanner.makePlan(
            deck: deck,
            deckCards: allCards,
            states: states,
            recentLogs: recentLogs,
            mode: selectedMode,
            requestedQuestionCount: questionCount
        )
        questionCount = plan.questionCount
        batches = plan.batches
        draftDrawingDataCache.removeAll()
        sessionMode = plan.mode
        currentBatchIndex = 0
        currentIndex = 0
        replaceCurrentDrawing(with: PKDrawing())
        startedAt = .now
        didRecordSession = false
        didFinishAnswering = false
        saveDraft()
    }

    func fetchSessionData() {
        let deckID = deck.id
        do {
            let data = try modelContext.fetchVocabularySessionData(
                deckID: deckID,
                direction: .definitionToTerm,
                statePropertiesToFetch: VocabularyMemoryState.sessionPropertiesToFetch
            )
            allCards = data.cards
            states = data.states
        } catch {
            allCards = []
            states = []
            alert = AppAlert(title: "无法读取测验题库", error: error)
        }
    }

    func fetchRecentReviewLogs(limit: Int) -> [VocabularyReviewLog] {
        do {
            return try modelContext.fetchVocabularyReviewLogs(
                deckID: deck.id,
                direction: .definitionToTerm,
                limit: limit,
                propertiesToFetch: VocabularyReviewLog.testSelectionPropertiesToFetch
            )
        } catch {
            alert = AppAlert(title: "无法读取复习记录", error: error)
            return []
        }
    }

    func replaceCurrentDrawing(with drawing: PKDrawing) {
        currentDrawing = drawing
        currentDrawingReloadToken &+= 1
    }

    func exitExam() {
        guard sessionMode == .exam else { return }
        guard saveDraft() else { return }

        cancelGradingTasks()
        refreshLatestDraft()
        selectedMode = .exam
        sessionMode = nil
        batches = []
        currentBatchIndex = 0
        currentIndex = 0
        replaceCurrentDrawing(with: PKDrawing())
        startedAt = .now
        didRecordSession = false
        didFinishAnswering = false
        enlargedImage = nil
        draftDrawingDataCache.removeAll()
    }
}
