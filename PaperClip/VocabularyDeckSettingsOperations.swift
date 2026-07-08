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

    @MainActor
    func startGeneratingEnglishDefinitions(_ snapshot: VocabularyDeckSettingsSnapshot) {
        definitionGenerationTaskSlot.cancel()
        isGeneratingDefinitions = false
        _ = definitionGenerationTaskSlot.start { taskID in
            await generateEnglishDefinitions(snapshot, taskID: taskID)
            definitionGenerationTaskSlot.finish(taskID)
        }
    }

    @MainActor
    func generateEnglishDefinitions(_ snapshot: VocabularyDeckSettingsSnapshot, taskID: UUID) async {
        guard !isGeneratingDefinitions else { return }

        let targets = snapshot.cards.filter {
            $0.englishDefinition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard !targets.isEmpty else { return }

        isGeneratingDefinitions = true
        generatedDefinitionCount = 0
        definitionGenerateError = nil
        saveError = nil

        let generatedDefinitions: [VocabularyGeneratedEnglishDefinition]
        do {
            generatedDefinitions = try await generateVocabularyEnglishDefinitions(
                for: targets,
                isCurrent: { definitionGenerationTaskSlot.isCurrent(taskID) },
                onProgress: { generatedDefinitionCount += $0 }
            )
        } catch is CancellationError {
            guard definitionGenerationTaskSlot.isCurrent(taskID) else { return }
            isGeneratingDefinitions = false
            return
        } catch {
            guard definitionGenerationTaskSlot.isCurrent(taskID) else { return }
            definitionGenerateError = "第 \(generatedDefinitionCount + 1) 项失败：\(error.localizedDescription)"
            isGeneratingDefinitions = false
            return
        }

        do {
            try Task.checkCancellation()
            guard definitionGenerationTaskSlot.isCurrent(taskID) else { return }
            var cardByID: [UUID: VocabularyCard] = [:]
            cardByID.reserveCapacity(targets.count)
            for card in targets {
                cardByID[card.id] = card
            }
            for item in generatedDefinitions {
                guard let card = cardByID[item.cardID],
                      card.englishDefinition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else { continue }
                card.englishDefinition = item.englishDefinition
                card.updatedAt = .now
            }
            deck.updatedAt = .now
            try modelContext.saveOrRollbackIfNeeded()
            definitionGenerateError = nil
            saveError = nil
        } catch is CancellationError {
            guard definitionGenerationTaskSlot.isCurrent(taskID) else { return }
            isGeneratingDefinitions = false
            return
        } catch {
            guard definitionGenerationTaskSlot.isCurrent(taskID) else { return }
            modelContext.rollback()
            saveError = "无法保存英文释义：\(error.localizedDescription)"
        }

        guard definitionGenerationTaskSlot.isCurrent(taskID) else { return }
        refreshDeckSettingsSnapshot()
        isGeneratingDefinitions = false
    }

    func cancelDefinitionGeneration() {
        definitionGenerationTaskSlot.cancel()
        isGeneratingDefinitions = false
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
