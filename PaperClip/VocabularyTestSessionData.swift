import Foundation
import PencilKit

extension VocabularyTestView {
    func startTest() {
        dismissAnswerAdvanceUndo()
        isConfirmingEmptyAnswer = false
        fetchSessionData()

        let selectionStrategy: VocabularyTestQuestionSelectionStrategy
        if handwritingTestKind == .englishDefinition {
            guard VocabularyEnglishDefinitionQuestionCount.canStart(
                availableQuestionCount: allCards.count
            ) else {
                if alert == nil {
                    alert = AppAlert(
                        title: "无法开始英文释义手写",
                        message: "至少需要 5 个已保存英文释义的词语。"
                    )
                }
                return
            }

            switch englishDefinitionTestMode {
            case .custom:
                let availableCardIDs = Set(allCards.map(\.id))
                let selectedCardIDs = selectedEnglishDefinitionCardIDs.intersection(availableCardIDs)
                guard VocabularyEnglishDefinitionQuestionCount.canStart(
                    availableQuestionCount: selectedCardIDs.count
                ) else {
                    alert = AppAlert(
                        title: "请选择更多词语",
                        message: "自定义选择至少需要 5 个词语。"
                    )
                    return
                }
                selectionStrategy = .custom(cardIDs: selectedCardIDs)
            case .random:
                selectionStrategy = .random
            }
        } else {
            guard selectedMode.canStart(cardCount: allCards.count) else {
                if alert == nil {
                    if selectedMode == .debug {
                        alert = AppAlert(
                            title: "无法开始调试",
                            message: "调试模式需要至少 5 个\(deck.kind.itemName)。"
                        )
                    } else {
                        alert = AppAlert(
                            title: "无法开始测验",
                            message: "\(deck.kind.collectionName)中没有可用\(deck.kind.itemName)。"
                        )
                    }
                }
                return
            }
            if selectedMode == .debug {
                selectionStrategy = .prioritized
            } else {
                switch selectedQuestionSelectionMode {
                case .ordered:
                    guard let range = VocabularyTestQuestionRange.validated(
                        startQuestion: Int(orderedStartQuestionText) ?? 0,
                        questionCount: Int(orderedQuestionCountText) ?? 0,
                        maximumQuestionCount: allCards.count
                    ) else {
                        alert = AppAlert(
                            title: "选题范围无效",
                            message: "当前 \(deck.kind.collectionName)共有 \(allCards.count) 题，请输入有效的起始题号和测验题数。"
                        )
                        return
                    }
                    selectionStrategy = .orderedRange(
                        startQuestion: range.lowerBound,
                        endQuestion: range.upperBound
                    )
                case .random:
                    selectionStrategy = .randomStandard
                }
            }
        }

        restartGradingSession()
        let recentLogs = selectionStrategy.usesReviewPriority
            ? fetchRecentReviewLogs(
                limit: VocabularyTestQuestionSelector.recentReviewLogLimit(cardCount: allCards.count)
            )
            : []
        let plan = VocabularyTestSessionPlanner.makePlan(
            deck: deck,
            deckCards: allCards,
            states: states,
            recentLogs: recentLogs,
            mode: selectedMode,
            requestedQuestionCount: questionCount,
            selectionStrategy: selectionStrategy
        )
        questionCount = plan.questionCount
        batches = plan.batches
        activeTestSelectionDescription = testSelectionDescription(for: selectionStrategy)
        draftDrawingDataCache.removeAll()
        sessionMode = plan.mode
        currentBatchIndex = 0
        currentIndex = 0
        replaceCurrentDrawing(with: PKDrawing())
        startedAt = .now
        didRecordSession = false
    }

    private func testSelectionDescription(
        for strategy: VocabularyTestQuestionSelectionStrategy
    ) -> String? {
        guard handwritingTestKind == .spelling, selectedMode != .debug else { return nil }
        switch strategy {
        case .randomStandard:
            return "随机"
        case let .orderedRange(startQuestion, endQuestion):
            return "按顺序 · 第 \(startQuestion)–\(endQuestion) 题"
        default:
            return nil
        }
    }

    func fetchSessionData() {
        let deckID = deck.id
        do {
            let data = try modelContext.fetchVocabularySessionData(
                deckID: deckID,
                direction: handwritingTestKind.reviewDirection,
                statePropertiesToFetch: VocabularyMemoryState.sessionPropertiesToFetch
            )
            allCards = data.cards.filter {
                handwritingTestKind.isEligible(englishDefinition: $0.englishDefinition)
            }
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
                direction: handwritingTestKind.reviewDirection,
                limit: limit,
                propertiesToFetch: VocabularyReviewLog.testSelectionPropertiesToFetch
            )
        } catch {
            alert = AppAlert(title: "无法读取复习记录", error: error)
            return []
        }
    }

    func replaceCurrentDrawing(with drawing: PKDrawing) {
        answerCanvasSession.prepare(drawing)
        currentDrawing = drawing
        currentDrawingReloadToken &+= 1
    }

}
