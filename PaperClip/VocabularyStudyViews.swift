import SwiftUI
import SwiftData

struct VocabularyStudyView: View {
    let deck: VocabularyDeck

    @Environment(\.modelContext) var modelContext

    @State var allCards: [VocabularyCard] = []
    @State var states: [VocabularyMemoryState] = []
    @State var queue: [VocabularyCard] = []
    @State var index = 0
    @State var hasChecked = false
    @State var isCorrect = false
    @State var correctTiles: [String] = []
    @State var wordBankTiles: [VocabularyWordBankTile] = []
    @State var placedTileIDs: [Int] = []
    @State var startedAt = Date.now
    @State var sessionStartedAt = Date.now
    @State var sessionItems: [VocabularyStudySessionItem] = []
    @State var didRecordSession = false
    @State var alert: AppAlert?

    @AppStorage("distractor.totalCount") var totalCount: Int = 8

    var current: VocabularyCard? {
        queue.indices.contains(index) ? queue[index] : nil
    }

    let maximumQueueCount = 24
    let maximumDistractorCount = 4

    init(deck: VocabularyDeck) {
        self.deck = deck
    }

    var body: some View {
        VStack(spacing: 22) {
            if queue.isEmpty {
                ContentUnavailableView("没有可学习的\(deck.kind.itemName)", systemImage: "brain.head.profile")
            } else if let card = current {
                VocabularyProgressHeader(index: index, total: queue.count)

                VocabularyWordBankQuestionView(
                    definition: card.definition,
                    wordBankTiles: wordBankTiles,
                    hasChecked: hasChecked,
                    placedTileIDs: $placedTileIDs
                )
                    .frame(maxWidth: 760)

                if hasChecked {
                    Label(
                        isCorrect ? "回答正确" : "正确答案：\(card.term)",
                        systemImage: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
                    )
                    .font(.headline)
                    .foregroundStyle(isCorrect ? Color.green : Color.red)

                    Button(index + 1 == queue.count ? "完成" : "下一题", systemImage: "arrow.right") {
                        advance(card)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("检查", systemImage: "checkmark") {
                        check(card)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(placedTileIDs.isEmpty)
                }
                Spacer()
            } else {
                VocabularySessionCompleteView(
                    title: "学习完成",
                    message: "本轮完成 \(queue.count) 道拼句练习。",
                    systemImage: "brain.head.profile.fill"
                )
            }
        }
        .padding(28)
        .navigationTitle("学习")
        .appAlert($alert)
        .task(id: deck.id) {
            if queue.isEmpty {
                startSession()
            }
        }
        .onChange(of: index) {
            prepareQuestion()
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
