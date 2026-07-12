import Foundation
import SwiftData

@main
struct VocabularyPersistenceTests {
    @MainActor
    static func main() throws {
        let schema = Schema([
            VocabularyFolder.self,
            VocabularyDeck.self,
            VocabularyCard.self,
            VocabularyGeneratedArticle.self,
            VocabularyArticleRecitationHistory.self,
            VocabularyMemoryState.self,
            VocabularyReviewLog.self,
            VocabularyStudySession.self,
            VocabularyTestDraft.self,
            VocabularyHandwritingAttempt.self,
            VocabularyDistractorCache.self,
            VocabularyImportBatch.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        let deck = VocabularyDeck(title: "FSRS Test")
        let card = VocabularyCard(deckID: deck.id, term: "memory", definition: "记忆")
        let folder = VocabularyFolder(title: "Unit 1")
        let state = VocabularyMemoryState(
            deckID: deck.id,
            cardID: card.id,
            direction: .definitionToTerm
        )
        let missingDeckState = VocabularyMemoryState(
            deckID: nil,
            cardID: card.id,
            direction: .termToDefinition
        )
        deck.folderID = folder.id
        context.insert(folder)
        context.insert(deck)
        context.insert(card)
        context.insert(state)
        context.insert(missingDeckState)
        try context.save()

        let cardRow = VocabularyCardRowData(card: card)
        expect(cardRow.matchesSearch(""))
        expect(cardRow.matchesSearch("memo"))
        expect(cardRow.matchesSearch("记忆"))
        expect(!cardRow.matchesSearch("遗忘"))

        let states = try context.fetch(FetchDescriptor<VocabularyMemoryState>())
        expect(states.count == 2)
        let folderID = folder.id
        let folderRows = try context.fetchVocabularyFolders(
            propertiesToFetch: VocabularyFolderRowData.propertiesToFetch
        ).map(VocabularyFolderRowData.init)
        let deckRows = try context.fetchVocabularyDecks(
            propertiesToFetch: VocabularyDeckRowData.propertiesToFetch
        ).map(VocabularyDeckRowData.init)
        expect(folderRows.count == 1)
        expect(folderRows.first?.title == "Unit 1")
        expect(deckRows.first?.folderID == folderID)
        expect(VocabularyFolder.deletionPropertiesToFetch.count == 1)
        expect(state.algorithmVersion == 6)
        expect(state.deckID == deck.id)
        expect(state.learningStep == 0)
        expect(state.scheduledDays == 0)
        expect(state.stability == 0)
        expect(state.difficulty == 0)
        expect(VocabularyDeck.deletionPropertiesToFetch.count == 1)
        expect(VocabularyCard.deletionPropertiesToFetch.count == 1)
        expect(VocabularyCard.homeCountPropertiesToFetch.count == 2)
        expect(VocabularyCard.deckSettingsPropertiesToFetch.count == 7)
        expect(VocabularyCard.articleGenerationPropertiesToFetch.count == 11)
        expect(VocabularyCard.importMergePropertiesToFetch.count == 8)
        expect(VocabularyGeneratedArticle.deletionPropertiesToFetch.count == 1)
        expect(VocabularyArticleRecitationHistory.deletionPropertiesToFetch.count == 1)
        expect(VocabularyMemoryState.deletionPropertiesToFetch.count == 1)
        expect(VocabularyMemoryState.futureDuePropertiesToFetch.count == 3)
        expect(VocabularyReviewLog.deletionPropertiesToFetch.count == 1)
        expect(VocabularyStudySession.deletionPropertiesToFetch.count == 1)
        expect(VocabularyTestDraft.deletionPropertiesToFetch.count == 1)
        expect(VocabularyHandwritingAttempt.deletionPropertiesToFetch.count == 1)
        expect(VocabularyImportBatch.deletionPropertiesToFetch.count == 1)
        expect(VocabularyDistractorCache.freshnessPropertiesToFetch.count == 2)
        expect(VocabularyDistractorCache.deletionPropertiesToFetch.count == 1)
        expect(missingDeckState.deckID == nil)

        try context.deleteVocabularyFolderPreservingDecks(folderID: folderID)
        try context.save()
        let foldersAfterDelete = try context.fetch(FetchDescriptor<VocabularyFolder>())
        let deckAfterFolderDelete = try context.fetchVocabularyDeck(id: deck.id)
        let cardsAfterFolderDelete = try context.fetchVocabularyCards(deckID: deck.id)
        expect(foldersAfterDelete.isEmpty)
        expect(deckAfterFolderDelete?.folderID == nil)
        expect(cardsAfterFolderDelete.count == 1)

        VocabularyMaintenance.backfillMemoryStateDeckIDs(in: container)

        expect(missingDeckState.deckID == deck.id)

        let importResult = VocabularyImportResult(
            format: .tab,
            rows: [
                VocabularyImportRow(
                    id: 0,
                    term: "memory",
                    definition: "记忆",
                    phonetic: "/mem/",
                    example: "Memory matters."
                ),
                VocabularyImportRow(
                    id: 1,
                    term: "focus",
                    definition: "专注"
                ),
                VocabularyImportRow(
                    id: 2,
                    term: "",
                    definition: "invalid",
                    error: "缺少词条"
                )
            ]
        )
        try VocabularyImportOperations.importRows(
            into: deck,
            in: context,
            sourceName: "import-fixture",
            preset: .tab,
            duplicateStrategy: .merge,
            importResult: importResult
        )

        let importedCards = try context.fetchVocabularyCards(deckID: deck.id)
        let importedBatches = try context.fetch(FetchDescriptor<VocabularyImportBatch>())
        expect(importedCards.count == 2)
        expect(card.phonetic == "/mem/")
        expect(card.example == "Memory matters.")
        expect(importedBatches.count == 1)
        expect(importedBatches.first?.importedCount == 1)
        expect(importedBatches.first?.skippedCount == 1)
        expect(importedBatches.first?.failedCount == 1)

        let reviewLog = VocabularyReviewLog(
            cardID: card.id,
            deckID: deck.id,
            direction: .definitionToTerm,
            rating: .again,
            responseKind: "test",
            duration: 1,
            previousStability: 0,
            resultingStability: 0
        )
        let studySession = VocabularyStudySession(
            deckID: deck.id,
            kind: "test",
            startedAt: .now,
            items: []
        )
        let flashcardSession = VocabularyStudySession(
            deckID: deck.id,
            kind: "闪卡",
            startedAt: .now,
            items: []
        )
        let legacyExamSession = VocabularyStudySession(
            deckID: deck.id,
            kind: "考试",
            startedAt: .now,
            items: []
        )
        let draft = VocabularyTestDraft(
            deckID: deck.id,
            mode: "regular",
            payload: VocabularyTestDraftSavePayload(
                batchSize: 1,
                currentBatchIndex: 0,
                currentQuestionIndex: 0,
                currentDrawingData: Data(),
                didFinishAnswering: false,
                startedAt: .now,
                batches: [
                    VocabularyTestDraftBatchSnapshot(
                        id: 1,
                        startIndex: 0,
                        cardIDs: [card.id],
                        drawingsData: [Data([1, 2, 3])],
                        status: "pending",
                        gradingAttempts: 2,
                        result: nil,
                        errorMessage: "retry"
                    )
                ]
            )
        )
        expect(draft.batches.count == 1)
        expect(draft.batches.first?.cardIDs == [card.id])
        expect(draft.batches.first?.drawingsData == [Data([1, 2, 3])])
        expect(draft.batches.first?.errorMessage == "retry")
        draft.batchesJSON = "not-json"
        expect(draft.batches.isEmpty)
        let handwritingAttempt = VocabularyHandwritingAttempt(
            cardID: card.id,
            deckID: deck.id,
            drawingData: Data(),
            isCorrect: false
        )
        let importBatch = VocabularyImportBatch(
            deckID: deck.id,
            sourceName: "fixture",
            detectedFormat: "plain",
            importedCount: 1,
            skippedCount: 0,
            failedCount: 0
        )
        let distractorCache = VocabularyDistractorCache(
            cardID: card.id,
            deckID: deck.id,
            correctTiles: ["memory"],
            distractorTiles: ["memo"],
            cardTermSnapshot: card.term
        )
        context.insert(reviewLog)
        context.insert(studySession)
        context.insert(flashcardSession)
        context.insert(legacyExamSession)
        context.insert(draft)
        context.insert(handwritingAttempt)
        context.insert(importBatch)
        context.insert(distractorCache)
        try context.save()

        let articleDraft = VocabularyArticleDraft(
            title: "Memory Day",
            articleText: "Memory matters. Focus helps memory.",
            coveredTerms: ["memory", "focus"],
            sourceCardSnapshotHash: "fixture",
            modelName: "deepseek-v4-pro",
            promptVersion: 1
        )
        let storedArticle = try context.upsertVocabularyGeneratedArticle(
            deckID: deck.id,
            draft: articleDraft
        )
        try context.save()
        let fetchedArticle = try context.fetchVocabularyGeneratedArticle(deckID: deck.id)
        expect(fetchedArticle?.id == storedArticle.id)
        expect(fetchedArticle?.title == "Memory Day")
        let recitationHistory = context.recordVocabularyArticleRecitationHistory(
            article: storedArticle,
            duration: 42,
            sentenceCount: 2,
            wordCount: 5,
            stuckSentenceIndexes: [1, 1, 0]
        )
        try context.save()
        let fetchedHistories = try context.fetchVocabularyArticleRecitationHistories(
            deckID: deck.id,
            articleSnapshotHash: "fixture"
        )
        expect(fetchedHistories.map(\.id) == [recitationHistory.id])
        expect(fetchedHistories.first?.stuckSentenceIndexes == [0, 1])
        expect(fetchedHistories.first?.duration == 42)

        let storyDrafts = [
            VocabularyArticleDraft(
                title: "The First Clue",
                articleText: "A short first story.",
                coveredTerms: ["memory"],
                sourceCardSnapshotHash: "series-2",
                modelName: "deepseek-v4-pro",
                promptVersion: 2
            ),
            VocabularyArticleDraft(
                title: "The Second Clue",
                articleText: "A short second story.",
                coveredTerms: ["focus"],
                sourceCardSnapshotHash: "series-2",
                modelName: "deepseek-v4-pro",
                promptVersion: 2
            )
        ]
        let storedStories = try context.insertVocabularyGeneratedArticleSeries(
            deckID: deck.id,
            drafts: storyDrafts
        )
        try context.save()
        let currentSeries = try context.fetchVocabularyGeneratedArticleSeries(deckID: deck.id)
        expect(storedStories.count == 2)
        expect(currentSeries.map(\.id) == storedStories.map(\.id))
        expect(currentSeries.map(\.title) == ["The First Clue", "The Second Clue"])
        expect(currentSeries.allSatisfy { $0.sourceCardSnapshotHash == "series-2" })
        let archivedArticles = try context.fetchVocabularyGeneratedArticleArchive(deckID: deck.id)
        expect(archivedArticles.map(\.id) == [storedArticle.id])
        let failedDraft = VocabularyArticleDraft(
            title: "Must Not Persist",
            articleText: "This pending story must be removed after a failed save.",
            coveredTerms: ["memory"],
            sourceCardSnapshotHash: "failed-series",
            modelName: "deepseek-v4-pro",
            promptVersion: 2
        )
        do {
            _ = try VocabularyArticleSeriesTransaction.commit(
                modelContext: context,
                deckID: deck.id,
                drafts: [failedDraft],
                saving: { _ in throw ExpectedSaveFailure() }
            )
            expect(false)
        } catch is ExpectedSaveFailure {
            // Expected: the transaction must remove its pending inserts before rethrowing.
        }
        let articlesAfterFailedSave = try context.fetch(FetchDescriptor<VocabularyGeneratedArticle>())
        expect(!articlesAfterFailedSave.contains { $0.sourceCardSnapshotHash == "failed-series" })
        let firstStoryHistory = context.recordVocabularyArticleRecitationHistory(
            article: storedStories[0],
            duration: 20,
            sentenceCount: 1,
            wordCount: 4,
            stuckSentenceIndexes: []
        )
        _ = context.recordVocabularyArticleRecitationHistory(
            article: storedStories[1],
            duration: 30,
            sentenceCount: 1,
            wordCount: 4,
            stuckSentenceIndexes: [0]
        )
        try context.save()
        let firstStoryHistories = try context.fetchVocabularyArticleRecitationHistories(
            articleID: storedStories[0].id
        )
        expect(firstStoryHistories.map(\.id) == [firstStoryHistory.id])

        let scoreSessions = try context.fetchVocabularyScoreSessions(
            deckID: deck.id,
            limit: 100,
            propertiesToFetch: [\.kind]
        )
        expect(scoreSessions.map(\.kind) == ["test"])

        let resetDeck = VocabularyDeck(title: "Reset Test")
        let resetCard = VocabularyCard(deckID: resetDeck.id, term: "reset", definition: "重置")
        let resetState = VocabularyMemoryState(
            deckID: resetDeck.id,
            cardID: resetCard.id,
            direction: .termToDefinition
        )
        let resetLog = VocabularyReviewLog(
            cardID: resetCard.id,
            deckID: resetDeck.id,
            direction: .termToDefinition,
            rating: .good,
            responseKind: "test",
            duration: 2,
            previousStability: 1,
            resultingStability: 2
        )
        let otherDeck = VocabularyDeck(title: "Other Test")
        let otherCard = VocabularyCard(deckID: otherDeck.id, term: "other", definition: "其他")
        let otherState = VocabularyMemoryState(
            deckID: otherDeck.id,
            cardID: otherCard.id,
            direction: .termToDefinition
        )
        let otherLog = VocabularyReviewLog(
            cardID: otherCard.id,
            deckID: otherDeck.id,
            direction: .termToDefinition,
            rating: .good,
            responseKind: "test",
            duration: 2,
            previousStability: 1,
            resultingStability: 2
        )
        context.insert(resetDeck)
        context.insert(resetCard)
        context.insert(resetState)
        context.insert(resetLog)
        context.insert(otherDeck)
        context.insert(otherCard)
        context.insert(otherState)
        context.insert(otherLog)
        try context.save()

        let resetResult = try context.resetVocabularyMastery(deckID: resetDeck.id)
        try context.save()
        let resetDeckID = resetDeck.id
        let otherDeckID = otherDeck.id
        let remainingResetStates = try context.fetchVocabularyMemoryStates(
            deckID: resetDeckID,
            propertiesToFetch: []
        )
        let remainingResetLogs = try context.fetch(FetchDescriptor<VocabularyReviewLog>(
            predicate: #Predicate<VocabularyReviewLog> { log in
                log.deckID == resetDeckID
            }
        ))
        let remainingResetCards = try context.fetchVocabularyCards(deckID: resetDeckID)
        let remainingOtherStates = try context.fetchVocabularyMemoryStates(
            deckID: otherDeckID,
            propertiesToFetch: []
        )
        let remainingOtherLogs = try context.fetch(FetchDescriptor<VocabularyReviewLog>(
            predicate: #Predicate<VocabularyReviewLog> { log in
                log.deckID == otherDeckID
            }
        ))
        expect(resetResult.memoryStateCount == 1)
        expect(resetResult.reviewLogCount == 1)
        expect(remainingResetStates.isEmpty)
        expect(remainingResetLogs.isEmpty)
        expect(remainingResetCards.count == 1)
        expect(remainingOtherStates.count == 1)
        expect(remainingOtherLogs.count == 1)

        try context.deleteVocabularyDeckCascade(deckID: deck.id)
        try context.deleteVocabularyDeckCascade(deckID: resetDeckID)
        try context.deleteVocabularyDeckCascade(deckID: otherDeckID)
        try context.save()

        let remainingDecks = try context.fetch(FetchDescriptor<VocabularyDeck>())
        let remainingCards = try context.fetch(FetchDescriptor<VocabularyCard>())
        let remainingStates = try context.fetch(FetchDescriptor<VocabularyMemoryState>())
        let remainingLogs = try context.fetch(FetchDescriptor<VocabularyReviewLog>())
        let remainingSessions = try context.fetch(FetchDescriptor<VocabularyStudySession>())
        let remainingDrafts = try context.fetch(FetchDescriptor<VocabularyTestDraft>())
        let remainingAttempts = try context.fetch(FetchDescriptor<VocabularyHandwritingAttempt>())
        let remainingBatches = try context.fetch(FetchDescriptor<VocabularyImportBatch>())
        let remainingCaches = try context.fetch(FetchDescriptor<VocabularyDistractorCache>())
        let remainingArticles = try context.fetch(FetchDescriptor<VocabularyGeneratedArticle>())
        let remainingArticleHistories = try context.fetch(FetchDescriptor<VocabularyArticleRecitationHistory>())

        expect(remainingDecks.isEmpty)
        expect(remainingCards.isEmpty)
        expect(remainingStates.isEmpty)
        expect(remainingLogs.isEmpty)
        expect(remainingSessions.isEmpty)
        expect(remainingDrafts.isEmpty)
        expect(remainingAttempts.isEmpty)
        expect(remainingBatches.isEmpty)
        expect(remainingCaches.isEmpty)
        expect(remainingArticles.isEmpty)
        expect(remainingArticleHistories.isEmpty)

        print("VocabularyPersistenceTests: 73 passed")
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError("Expectation failed", file: file, line: line)
        }
    }

    private struct ExpectedSaveFailure: Error {}
}
