import SwiftUI
import SwiftData

// MARK: - SubjectMistakesView（学科内卡片网格）

enum SubjectMistakeSection: String, CaseIterable, Identifiable {
    case mistakes = "错题"
    case knowledgePoints = "知识点"
    case formulas = "公式"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .mistakes: "rectangle.stack"
        case .knowledgePoints: "point.3.connected.trianglepath.dotted"
        case .formulas: "function"
        }
    }
}

struct SubjectMistakesView: View {
    let subject: String?
    let section: SubjectMistakeSection?

    @Environment(\.modelContext) var modelContext

    @State var searchText = ""
    @State var selectedStatus = ""
    @State var selectedQuestionType = ""
    @State var selectedTag = ""
    @State var selectedSource = ""
    @State var cards: [MistakeCardRowData] = []
    @State var editingCard: MistakeCardRowData?
    @State var isPaperSelectionPresented = false
    @State var paperSelectionCards: [MistakeCardRowData] = []
    @State var practiceRoundCountByCardID: [UUID: Int] = [:]
    @State var alert: AppAlert?

    init(subject: String?, section: SubjectMistakeSection? = .mistakes) {
        self.subject = subject
        self.section = section
    }

    var mistakeSnapshot: MistakeListSnapshot {
        MistakeListSnapshot(
            cards: cards,
            searchText: searchText,
            selectedStatus: selectedStatus,
            selectedQuestionType: selectedQuestionType,
            selectedTag: selectedTag,
            selectedSource: selectedSource
        )
    }

    var body: some View {
        Group {
            switch section {
            case .mistakes:
                mistakeContent
            case .knowledgePoints:
                referencePage(kind: .knowledgePoints)
            case .formulas:
                referencePage(kind: .formulas)
            case nil:
                ContentUnavailableView("请选择内容", systemImage: "rectangle.stack")
            }
        }
        .navigationTitle(section?.rawValue ?? subject ?? "错题")
        .sheet(item: $editingCard) { card in
            NavigationStack { MistakeCardEditorLoader(cardID: card.id) }
                .presentationDetents([.large])
        }
        .onChange(of: editingCard?.id) { oldValue, newValue in
            if oldValue != nil && newValue == nil {
                refreshCards()
            }
        }
        .sheet(isPresented: $isPaperSelectionPresented) {
            PaperCardSelectionView(availableCards: paperSelectionCards, subject: subject)
        }
        .appAlert($alert)
        .task(id: subject) {
            refreshCards()
        }
    }

}
