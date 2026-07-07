import SwiftData
import SwiftUI

struct VocabularyDeckSettingsView: View {
    let deck: VocabularyDeck

    @Environment(\.modelContext) var modelContext

    @State var titleDraft: String
    @State var cards: [VocabularyCard] = []
    @State var freshCacheCount = 0
    @State var isGenerating = false
    @State var generationTaskSlot = ViewTaskSlot()
    @State var generatedCount = 0
    @State var generateError: String?
    @State var saveError: String?

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
                TextField("词集名称", text: $titleDraft)
                    .submitLabel(.done)
                    .onSubmit(saveDeckTitle)
                if titleDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("词集名称不能为空。")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            VocabularyDeckSchedulingSection(
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

            VocabularyDeckDistractorConfigSection(
                totalCount: $totalCount,
                weightInflection: $weightInflection,
                weightLookalike: $weightLookalike,
                weightSynonym: $weightSynonym,
                weightConfused: $weightConfused,
                weightDerivation: $weightDerivation
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
        .navigationTitle("词集设置")
        .onAppear {
            titleDraft = deck.title
        }
        .task(id: deck.id) {
            refreshDeckSettingsSnapshot()
        }
        .onDisappear {
            cancelGeneration()
            saveDeckTitle()
        }
    }
}
