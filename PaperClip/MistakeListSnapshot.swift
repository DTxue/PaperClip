import Foundation

struct MistakeListSnapshot {
    let filteredCards: [MistakeCardRowData]
    let filteredCardIDs: [UUID]
    let allSources: [String]
    let topTags: [(tag: String, count: Int)]
    let masterySummary: MasteryStatusSummary
    let emptyState: MistakeListEmptyState

    init(
        cards: [MistakeCardRowData],
        searchText: String,
        selectedStatus: String,
        selectedQuestionType: String,
        selectedTag: String,
        selectedSource: String
    ) {
        let query = MistakeCardFilterQuery(
            searchText: searchText,
            selectedStatus: selectedStatus,
            selectedQuestionType: selectedQuestionType,
            selectedTag: selectedTag,
            selectedSource: selectedSource
        )
        var filteredCards: [MistakeCardRowData] = []
        filteredCards.reserveCapacity(cards.count)
        var sourceSet: Set<String> = []
        var tagCounts: [String: Int] = [:]
        var masteryCounter = MasteryStatusCounter()

        for card in cards {
            masteryCounter.add(card.status)

            if !card.sourceDocumentTitle.isEmpty {
                sourceSet.insert(card.sourceDocumentTitle)
            }
            MistakeTagSummary.add(card.tags, to: &tagCounts)

            if query.matches(card) {
                filteredCards.append(card)
            }
        }

        self.filteredCards = filteredCards
        self.filteredCardIDs = filteredCards.map(\.id)
        self.allSources = sourceSet.sorted()
        self.topTags = MistakeTagSummary.topTags(from: tagCounts, limit: 15)
        self.masterySummary = masteryCounter.summary
        self.emptyState = MistakeListEmptyState(
            hasCards: !cards.isEmpty,
            selectedSource: selectedSource,
            selectedTag: selectedTag
        )
    }
}

struct MistakeListEmptyState: Equatable {
    let title: String
    let description: String

    init(hasCards: Bool, selectedSource: String, selectedTag: String) {
        if !hasCards {
            title = "还没有错题"
            description = "在 PDF 做题页使用「框选错题」创建第一张错题卡。"
        } else if !selectedSource.isEmpty {
            title = "没有符合条件的错题"
            description = "试卷「\(selectedSource)」下暂无符合条件的错题。"
        } else if !selectedTag.isEmpty {
            title = "没有符合条件的错题"
            description = "知识点「\(selectedTag)」下暂无错题。"
        } else {
            title = "没有符合条件的错题"
            description = "试试调整状态筛选条件。"
        }
    }
}
