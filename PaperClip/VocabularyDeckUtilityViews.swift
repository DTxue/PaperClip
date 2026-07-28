import SwiftData
import SwiftUI

struct VocabularyDeckSettingsView: View {
    let deck: VocabularyDeck

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State var titleDraft: String
    @State var cards: [VocabularyCard] = []
    @State var freshCacheCount = 0
    @State var isGenerating = false
    @State var generationTaskSlot = ViewTaskSlot()
    @State var generatedCount = 0
    @State var generateError: String?
    @State var definitionGenerationTaskSlot = ViewTaskSlot()
    @State var isGeneratingDefinitions = false
    @State var generatedDefinitionCount = 0
    @State var definitionGenerateError: String?
    @State var saveError: String?
    @State var alert: AppAlert?
    @State var deckDeleteRequest: VocabularyDeckDeleteRequest?
    @State var isDeletingDeck = false

    @AppStorage("distractor.totalCount") var totalCount: Int = 8
    @AppStorage("distractor.weight.inflection") var weightInflection: Int = 3
    @AppStorage("distractor.weight.lookalike") var weightLookalike: Int = 2
    @AppStorage("distractor.weight.synonym") var weightSynonym: Int = 2
    @AppStorage("distractor.weight.confused") var weightConfused: Int = 2
    @AppStorage("distractor.weight.derivation") var weightDerivation: Int = 1

    init(deck: VocabularyDeck) {
        self.deck = deck
        _titleDraft = State(initialValue: deck.title)
    }

    var body: some View {
        let snapshot = VocabularyDeckSettingsSnapshot(
            cards: cards,
            freshCacheCount: freshCacheCount
        )

        Form {
            Section("基本信息") {
                TextField("\(deck.kind.collectionName)名称", text: $titleDraft)
                    .submitLabel(.done)
                    .onSubmit(saveDeckTitle)
                if titleDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("\(deck.kind.collectionName)名称不能为空。")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            VocabularyDeckSchedulingSection(
                kind: deck.kind,
                dailyNewLimit: Binding(
                    get: { deck.dailyNewLimit },
                    set: {
                        deck.dailyNewLimit = $0
                        saveDeckSettings()
                    }
                ),
                desiredRetention: Binding(
                    get: { deck.desiredRetention },
                    set: {
                        deck.desiredRetention = $0
                        saveDeckSettings()
                    }
                )
            )

            if deck.kind.usesWordSpecificFeatures {
                VocabularyDeckDistractorConfigSection(
                    totalCount: $totalCount,
                    weightInflection: $weightInflection,
                    weightLookalike: $weightLookalike,
                    weightSynonym: $weightSynonym,
                    weightConfused: $weightConfused,
                    weightDerivation: $weightDerivation
                )

                VocabularyDeckEnglishDefinitionSection(
                    snapshot: snapshot,
                    isGenerating: isGeneratingDefinitions,
                    generatedCount: generatedDefinitionCount,
                    generateError: definitionGenerateError,
                    onGenerate: {
                        startGeneratingEnglishDefinitions(snapshot)
                    }
                )

                VocabularyDeckDistractorLibrarySection(
                    snapshot: snapshot,
                    isGenerating: isGenerating,
                    generatedCount: generatedCount,
                    saveError: saveError,
                    generateError: generateError,
                    onRegenerate: {
                        startRegeneratingAll(snapshot)
                    }
                )
            }

            VocabularyDeckDangerSection(kind: deck.kind) {
                deckDeleteRequest = VocabularyDeckDeleteRequest(
                    id: deck.id,
                    title: deck.title
                )
            }
        }
        .navigationTitle("\(deck.kind.collectionName)设置")
        .onAppear {
            titleDraft = deck.title
        }
        .task(id: deck.id) {
            refreshDeckSettingsSnapshot()
        }
        .onDisappear {
            cancelGeneration()
            cancelDefinitionGeneration()
            if !isDeletingDeck {
                saveDeckTitle()
            }
        }
        .deleteConfirmationDialog(
            item: $deckDeleteRequest,
            title: { "删除\(deck.kind.collectionName)「\($0.title)」？" },
            message: { _ in
                "该\(deck.kind.collectionName)中的\(deck.kind.itemName)、复习记录和手写记录都会删除，无法撤销。"
            },
            onDelete: deleteDeck
        )
        .appAlert($alert)
    }
}
