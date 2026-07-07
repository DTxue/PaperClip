import Foundation

struct DiaryKnowledgeSnapshot {
    let learnedDrafts: [KnowledgeItem]
    let confusedDrafts: [KnowledgeItem]
    let confirmedItems: [KnowledgeItem]
    let draftAnalysisTotal: Int
    let draftAnalysisDone: Int
    let hasDrafts: Bool

    init(items: [KnowledgeItem]) {
        var learnedDrafts: [KnowledgeItem] = []
        var confusedDrafts: [KnowledgeItem] = []
        var confirmedItems: [KnowledgeItem] = []
        var draftAnalysisTotal = 0
        var draftAnalysisDone = 0
        var hasDrafts = false

        for item in items {
            if item.status == "confirmed" {
                confirmedItems.append(item)
                continue
            }
            guard item.status == "draft" else { continue }
            hasDrafts = true
            if item.source == "learned" {
                learnedDrafts.append(item)
            } else if item.source == "confused" {
                confusedDrafts.append(item)
            }
            if !item.summary.isEmpty {
                draftAnalysisTotal += 1
                if item.aiAnalysisState == "done" {
                    draftAnalysisDone += 1
                }
            }
        }

        self.learnedDrafts = Self.oldestFirst(learnedDrafts)
        self.confusedDrafts = Self.oldestFirst(confusedDrafts)
        self.confirmedItems = Self.oldestFirst(confirmedItems)
        self.draftAnalysisTotal = draftAnalysisTotal
        self.draftAnalysisDone = draftAnalysisDone
        self.hasDrafts = hasDrafts
    }

    static func oldestFirst(_ items: [KnowledgeItem]) -> [KnowledgeItem] {
        guard items.count > 1 else { return items }
        for index in items.indices.dropFirst() where items[index - 1].createdAt > items[index].createdAt {
            return items.sorted { $0.createdAt < $1.createdAt }
        }
        return items
    }
}

enum DiaryKnowledgeAnalysisApplier {
    static func apply(_ result: KnowledgeAnalysis, to item: KnowledgeItem) -> Bool {
        item.applyAnalysis(result)
    }

    static func markFailed(_ item: KnowledgeItem) -> Bool {
        item.markAnalysisFailed()
    }
}
