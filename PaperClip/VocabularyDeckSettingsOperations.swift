import Foundation

extension VocabularyDeckSettingsView {
    @MainActor
    func startRegeneratingAll(_ snapshot: VocabularyDeckSettingsSnapshot) {
        generationTaskSlot.cancel()
        isGenerating = false
        _ = generationTaskSlot.start { taskID in
            await regenerateAll(snapshot, taskID: taskID)
            generationTaskSlot.finish(taskID)
        }
    }

    @MainActor
    func regenerateAll(_ snapshot: VocabularyDeckSettingsSnapshot, taskID: UUID) async {
        guard !isGenerating else { return }
        isGenerating = true
        generatedCount = 0
        generateError = nil
        saveError = nil

        let generatedCaches: [VocabularyGeneratedDistractorCache]
        do {
            generatedCaches = try await generateVocabularyDistractorCaches(
                for: snapshot.cards,
                deckID: deck.id,
                config: currentDistractorConfig,
                isCurrent: { generationTaskSlot.isCurrent(taskID) },
                onProgress: { generatedCount += 1 }
            )
        } catch is CancellationError {
            guard generationTaskSlot.isCurrent(taskID) else { return }
            isGenerating = false
            return
        } catch {
            guard generationTaskSlot.isCurrent(taskID) else { return }
            generateError = "第 \(generatedCount + 1) 项失败：\(error.localizedDescription)"
            isGenerating = false
            return
        }

        do {
            try Task.checkCancellation()
            guard generationTaskSlot.isCurrent(taskID) else { return }
            try modelContext.replaceVocabularyDistractorCaches(
                deckID: deck.id,
                with: generatedCaches
            )
            freshCacheCount = generatedCaches.count
            generateError = nil
            saveError = nil
        } catch is CancellationError {
            guard generationTaskSlot.isCurrent(taskID) else { return }
            isGenerating = false
            return
        } catch {
            guard generationTaskSlot.isCurrent(taskID) else { return }
            modelContext.rollback()
            saveError = "无法保存干扰词库：\(error.localizedDescription)"
        }
        guard generationTaskSlot.isCurrent(taskID) else { return }
        refreshDeckSettingsSnapshot()
        isGenerating = false
    }

    func cancelGeneration() {
        generationTaskSlot.cancel()
        isGenerating = false
    }

    private var currentDistractorConfig: DistractorConfig {
        DistractorConfig(
            totalCount: totalCount,
            weightInflection: weightInflection,
            weightLookalike: weightLookalike,
            weightSynonym: weightSynonym,
            weightConfused: weightConfused,
            weightDerivation: weightDerivation
        )
    }
}
