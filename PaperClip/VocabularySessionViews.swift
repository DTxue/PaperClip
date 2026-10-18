import SwiftUI
import SwiftData
import PencilKit

struct VocabularyTestView: View {
    let deck: VocabularyDeck
    let handwritingTestKind: VocabularyHandwritingTestKind

    @Environment(\.modelContext) var modelContext
    @AppStorage var usesChineseCharacterByCharacterRecognition: Bool
    @AppStorage var usesLocalChineseRecognition: Bool

    @State var allCards: [VocabularyCard] = []
    @State var states: [VocabularyMemoryState] = []
    @State var selectedMode: VocabularyTestMode = .regular
    @State var selectedQuestionSelectionMode: VocabularyTestQuestionSelectionMode = .random
    @State var englishDefinitionTestMode: VocabularyEnglishDefinitionTestMode = .random
    @State var selectedEnglishDefinitionCardIDs: Set<UUID> = []
    @State var orderedStartQuestionText = "1"
    @State var orderedQuestionCountText = "1"
    @State var activeTestSelectionDescription: String?
    @State var sessionMode: VocabularyTestMode?
    @State var questionCount = 5
    @State var batches: [VocabularyTestBatch] = []
    @State var currentBatchIndex = 0
    @State var currentIndex = 0
    @State var currentDrawing = PKDrawing()
    @State var currentDrawingReloadToken = 0
    @State var answerCanvasSession = VocabularyAnswerCanvasSession()
    @State var enlargedImage: IdentifiableImage? = nil
    @State var startedAt = Date.now
    @State var didRecordSession = false
    @State var draftDrawingDataCache = VocabularyDraftDrawingDataCache()
    @State var gradingTaskStore = VocabularyTestGradingTaskStore()
    @State var answerAdvanceUndoTarget: VocabularyAnswerAdvanceUndoTarget?
    @State var answerAdvanceUndoDismissAction = DebouncedAction()
    @State var isConfirmingEmptyAnswer = false
    @State var isConfirmingTestExit = false
    @State var alert: AppAlert?

    init(
        deck: VocabularyDeck,
        handwritingTestKind: VocabularyHandwritingTestKind = .spelling
    ) {
        self.deck = deck
        self.handwritingTestKind = handwritingTestKind
        _usesChineseCharacterByCharacterRecognition = AppStorage(
            wrappedValue: false,
            VocabularyChineseRecognitionPreference.storageKey(deckID: deck.id)
        )
        _usesLocalChineseRecognition = AppStorage(
            wrappedValue: true,
            VocabularyChineseRecognitionPreference.localRecognitionStorageKey(deckID: deck.id)
        )
    }
}

extension VocabularyHandwritingTestKind {
    var navigationTitle: String {
        switch self {
        case .spelling: "测验"
        case .englishDefinition: "英文释义手写"
        }
    }

    var completionTitle: String {
        switch self {
        case .spelling: "测验完成"
        case .englishDefinition: "英文释义手写完成"
        }
    }

    var gradingMessage: String {
        switch self {
        case .spelling: "AI 正在批改中…"
        case .englishDefinition: "AI 正在识别，系统正在参考批阅…"
        }
    }

    var sessionKind: String {
        switch self {
        case .spelling: "测验"
        case .englishDefinition: "英文释义手写"
        }
    }
}
