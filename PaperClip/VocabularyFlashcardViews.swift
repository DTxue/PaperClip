import SwiftUI
import SwiftData

/// 原生 API 评估：SwiftUI 提供 DragGesture、Button、系统动画和无障碍动作，
/// 但没有可将闪卡按 FSRS 评分分组并按轮重学的系统组件。
/// 这里的自定义手势只负责闪卡业务分类；点击翻面、替代按钮、VoiceOver 动作、
/// Dynamic Type、深色模式和窗口尺寸变化仍由 SwiftUI 系统能力承担。
struct VocabularyFlashcardView: View {
    let deck: VocabularyDeck

    @Environment(\.modelContext) var modelContext
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @State var allCards: [VocabularyCard] = []
    @State var states: [VocabularyMemoryState] = []
    @State var queue: [VocabularyCard] = []
    @State var nextRound: [VocabularyCard] = []
    @State var index = 0
    @State var initialCount = 0
    @State var round = 1
    @State var roundKnownCount = 0
    @State var roundLearningCount = 0
    @State var completedCardIDs: Set<UUID> = []
    @State var isRevealed = false
    @State var direction = VocabularyDirection.termToDefinition
    @State var startedAt = Date.now
    @State var sessionStartedAt = Date.now
    @State var sessionItems: [VocabularyStudySessionItem] = []
    @State var didRecordSession = false
    @State var swipeOffset = CGSize.zero
    @GestureState var activeDrag = VocabularyFlashcardDragState.inactive
    @State var cardEntryOffset: CGFloat = 0
    @State var cardEntryOpacity = 1.0
    @State var isAnimatingSwipe = false
    @State var roundFinished = false
    @State var sessionFinished = false
    @State var alert: AppAlert?

    init(deck: VocabularyDeck) {
        self.deck = deck
    }

    var current: VocabularyCard? {
        queue.indices.contains(index) ? queue[index] : nil
    }

    var cardOffset: CGSize {
        activeDrag.axis == .horizontal ? activeDrag.translation : swipeOffset
    }

    var body: some View {
        VStack(spacing: 24) {
            flashcardSessionContent
        }
        .padding(28)
        .navigationTitle("闪卡")
        .appAlert($alert)
        .toolbar {
            if let current {
                ToolbarItem(placement: .primaryAction) {
                    Button("朗读", systemImage: "speaker.wave.2") {
                        VocabularySpeech.speak(current.term)
                    }
                }
            }
        }
        .task(id: deck.id) {
            if queue.isEmpty {
                resetSession()
            }
        }
        .onChange(of: direction) {
            do {
                try modelContext.saveOrRollbackIfNeeded()
            } catch {
                alert = AppAlert(title: "无法保存学习进度", error: error)
            }
            resetSession()
        }
        .onDisappear {
            do {
                try modelContext.saveOrRollbackIfNeeded()
            } catch {
                alert = AppAlert(title: "无法保存学习进度", error: error)
            }
        }
    }


}
