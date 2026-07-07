import SwiftUI
import SwiftData
import PencilKit

struct VocabularyTestView: View {
    let deck: VocabularyDeck

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
    @State var enlargedImage: IdentifiableImage? = nil
    @State var startedAt = Date.now
    @State var didRecordSession = false
    @State var didFinishAnswering = false
    @State var draftSaveAction = DebouncedAction()
    @State var draftDrawingDataCache = VocabularyDraftDrawingDataCache()
    @State var gradingTaskStore = VocabularyTestGradingTaskStore()
    @State var alert: AppAlert?

    init(deck: VocabularyDeck) {
        self.deck = deck
    }
}
