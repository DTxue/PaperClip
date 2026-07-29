import SwiftUI
import SwiftData
import PencilKit

struct VocabularyTestView: View {
    let deck: VocabularyDeck
    let handwritingTestKind: VocabularyHandwritingTestKind

    @Environment(\.modelContext) var modelContext

    @State var allCards: [VocabularyCard] = []
    @State var states: [VocabularyMemoryState] = []
    @State var selectedMode: VocabularyTestMode = .regular
    @State var sessionMode: VocabularyTestMode?
    @State var questionCount = 5
    @State var latestDraft: VocabularyTestDraft?
    @State var batches: [VocabularyTestBatch] = []
    @State var currentBatchIndex = 0
    @State var currentIndex = 0
    @State var currentDrawing = PKDrawing()
    @State var currentDrawingReloadToken = 0
    @State var answerCanvasSession = VocabularyAnswerCanvasSession()
    @State var enlargedImage: IdentifiableImage? = nil
    @State var startedAt = Date.now
    @State var didRecordSession = false
    @State var didFinishAnswering = false
    @State var draftSaveAction = DebouncedAction()
    @State var draftDrawingDataCache = VocabularyDraftDrawingDataCache()
    @State var gradingTaskStore = VocabularyTestGradingTaskStore()
    @State var alert: AppAlert?

    init(
        deck: VocabularyDeck,
        handwritingTestKind: VocabularyHandwritingTestKind = .spelling
    ) {
        self.deck = deck
        self.handwritingTestKind = handwritingTestKind
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
