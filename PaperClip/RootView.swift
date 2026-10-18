import SwiftUI
import SwiftData
import UIKit

enum AppSection: Int {
    case home
    case dictation
    case statistics
    case settings
}

struct RootView: View {
    @State private var section: AppSection = .home

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .phone {
                IPhoneEnglishRootView()
            } else {
                iPadRootView
            }
        }
    }

    private var iPadRootView: some View {
        TabView(selection: $section) {
            Tab("日记", systemImage: "book.fill", value: .home) {
                HomeView()
            }

            Tab("默写", systemImage: "pencil.line", value: .dictation) {
                NavigationStack {
                    VocabularyDictationHomeView()
                }
            }

            Tab("统计", systemImage: "chart.bar", value: .statistics) {
                StatisticsView(isActive: section == .statistics)
            }

            Tab("设置", systemImage: "gearshape", value: .settings) {
                SettingsView()
            }
        }
        .tabViewStyle(.tabBarOnly)
    }
}

private struct IPhoneEnglishRootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var decks: [VocabularyDeckRowData] = []
    @State private var kindToCreate: VocabularyDeckKind?
    @State private var alert: AppAlert?

    private var englishDecks: [VocabularyDeckRowData] {
        decks.filter { $0.kind.homeBoard == .english }
    }

    var body: some View {
        NavigationStack {
            List(englishDecks) { deck in
                NavigationLink {
                    IPhoneEnglishDeckActionsView(deckID: deck.id, title: deck.title)
                } label: {
                    Label(deck.title, systemImage: deck.kind == .sentence ? "text.quote" : "character.book.closed")
                }
            }
            .overlay {
                if englishDecks.isEmpty {
                    ContentUnavailableView {
                        Label("没有 ENG 学习集", systemImage: "character.book.closed")
                    } description: {
                        Text("创建或导入词集、句集后即可开始学习。")
                    } actions: {
                        createDeckButtons
                    }
                }
            }
            .navigationTitle("ENG")
            .task { refreshDecks() }
            .refreshable { refreshDecks() }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        createDeckButtons
                    } label: {
                        Label("新增", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    NavigationLink {
                        AISettingsView()
                    } label: {
                        Label("AI API 设置", systemImage: "key")
                    }
                }
            }
            .sheet(item: $kindToCreate, onDismiss: refreshDecks) { kind in
                NavigationStack {
                    VocabularyDeckCreateView(kind: kind)
                }
            }
            .appAlert($alert)
        }
    }

    @ViewBuilder
    private var createDeckButtons: some View {
        Button("新增词集", systemImage: "character.book.closed") {
            kindToCreate = .word
        }
        Button("新增句集", systemImage: "text.quote") {
            kindToCreate = .sentence
        }
    }

    private func refreshDecks() {
        do {
            decks = try modelContext.fetchVocabularyDecks(
                propertiesToFetch: VocabularyDeckRowData.propertiesToFetch
            ).map(VocabularyDeckRowData.init)
        } catch {
            decks = []
            alert = AppAlert(title: "无法读取 ENG 学习集", error: error)
        }
    }
}

private struct IPhoneEnglishDeckActionsView: View {
    @Environment(\.modelContext) private var modelContext
    let deckID: UUID
    let title: String
    @State private var deck: VocabularyDeck?
    @State private var alert: AppAlert?

    var body: some View {
        Group {
            if let deck {
                List {
                    NavigationLink {
                        VocabularyFlashcardView(deck: deck)
                    } label: {
                        Label("闪卡", systemImage: "rectangle.on.rectangle")
                    }
                    NavigationLink {
                        VocabularyStudyView(deck: deck)
                    } label: {
                        Label("学习", systemImage: "brain.head.profile")
                    }
                    if deck.kind == .word {
                        NavigationLink {
                            IPhoneVocabularyDistractorView(deck: deck)
                        } label: {
                            Label("AI 干扰词库", systemImage: "sparkles")
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(title)
        .task(id: deckID) { loadDeck() }
        .appAlert($alert)
    }

    private func loadDeck() {
        do {
            guard let loadedDeck = try modelContext.fetchVocabularyDeck(id: deckID),
                  loadedDeck.kind.homeBoard == .english else {
                deck = nil
                return
            }
            deck = loadedDeck
        } catch {
            deck = nil
            alert = AppAlert(title: "无法打开学习集", error: error)
        }
    }
}

private struct IPhoneVocabularyDistractorView: View {
    let deck: VocabularyDeck

    @Environment(\.modelContext) private var modelContext
    @State private var cards: [VocabularyCard] = []
    @State private var freshCacheCount = 0
    @State private var isGenerating = false
    @State private var generatedCount = 0
    @State private var generationTask: Task<Void, Never>?
    @State private var saveError: String?
    @State private var generateError: String?
    @State private var alert: AppAlert?

    @AppStorage("distractor.totalCount") private var totalCount = 8
    @AppStorage("distractor.weight.inflection") private var weightInflection = 3
    @AppStorage("distractor.weight.lookalike") private var weightLookalike = 2
    @AppStorage("distractor.weight.synonym") private var weightSynonym = 2
    @AppStorage("distractor.weight.confused") private var weightConfused = 2
    @AppStorage("distractor.weight.derivation") private var weightDerivation = 1

    private var snapshot: VocabularyDeckSettingsSnapshot {
        VocabularyDeckSettingsSnapshot(cards: cards, freshCacheCount: freshCacheCount)
    }

    var body: some View {
        Form {
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
                onRegenerate: generate
            )
            Section {
                NavigationLink {
                    AISettingsView()
                } label: {
                    Label("AI API 设置", systemImage: "key")
                }
            } footer: {
                Text("重新生成前，请先在 AI API 设置中填写火山方舟或 DeepSeek API Key。")
            }
        }
        .navigationTitle("AI 干扰词库")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: deck.id) { refresh() }
        .onDisappear { generationTask?.cancel() }
        .appAlert($alert)
    }

    private func refresh() {
        do {
            cards = try modelContext.fetchVocabularyCards(
                deckID: deck.id,
                propertiesToFetch: VocabularyCard.deckSettingsPropertiesToFetch
            )
            let termByID = Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0.term) })
            let caches = try modelContext.fetchVocabularyDistractorCaches(
                deckID: deck.id,
                propertiesToFetch: VocabularyDistractorCache.freshnessPropertiesToFetch
            )
            freshCacheCount = caches.reduce(into: 0) { count, cache in
                if termByID[cache.cardID] == cache.cardTermSnapshot { count += 1 }
            }
        } catch {
            cards = []
            freshCacheCount = 0
            alert = AppAlert(title: "无法读取干扰词库", error: error)
        }
    }

    private func generate() {
        guard !isGenerating else { return }
        isGenerating = true
        generatedCount = 0
        generateError = nil
        saveError = nil
        let config = DistractorConfig(
            totalCount: totalCount,
            weightInflection: weightInflection,
            weightLookalike: weightLookalike,
            weightSynonym: weightSynonym,
            weightConfused: weightConfused,
            weightDerivation: weightDerivation
        )
        generationTask = Task { @MainActor in
            defer { isGenerating = false }
            do {
                let generated = try await generateVocabularyDistractorCaches(
                    for: cards,
                    deckID: deck.id,
                    config: config,
                    isCurrent: { !Task.isCancelled },
                    onProgress: { generatedCount += 1 }
                )
                try Task.checkCancellation()
                try modelContext.replaceVocabularyDistractorCaches(deckID: deck.id, with: generated)
                refresh()
            } catch is CancellationError {
                return
            } catch {
                generateError = "第 \(generatedCount + 1) 项失败：\(error.localizedDescription)"
            }
        }
    }
}
