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
    @AppStorage private var usesChineseCharacterByCharacterRecognition: Bool
    @AppStorage private var usesLocalChineseRecognition: Bool

    init(deck: VocabularyDeck) {
        self.deck = deck
        _titleDraft = State(initialValue: deck.title)
        _usesChineseCharacterByCharacterRecognition = AppStorage(
            wrappedValue: false,
            VocabularyChineseRecognitionPreference.storageKey(deckID: deck.id)
        )
        _usesLocalChineseRecognition = AppStorage(
            wrappedValue: true,
            VocabularyChineseRecognitionPreference.localRecognitionStorageKey(deckID: deck.id)
        )
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
            } else if deck.kind == .sentence {
                VocabularyDeckSentenceDistractorConfigSection(totalCount: $totalCount)
            } else if deck.kind == .dictationChinese {
                Section {
                    Toggle("本地识别", isOn: $usesLocalChineseRecognition)
                    Toggle("逐字识别", isOn: $usesChineseCharacterByCharacterRecognition)
                } header: {
                    Text("中文默写识别")
                } footer: {
                    Text("开启“本地识别”时，笔迹只在设备上处理；关闭时会将答案图片发送给 AI 识别。开启“逐字识别”后，每格单独识别且不参考整句；关闭后识别整张答案图。")
                }
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
