import Foundation

enum VocabularyGradingPolicy {
    static func validated(
        _ result: VocabularyGradingResult,
        hasVisibleAnswers: [Bool]
    ) -> VocabularyGradingResult {
        var itemByIndex: [Int: VocabularyGradingItem] = [:]
        for item in result.items
        where hasVisibleAnswers.indices.contains(item.index - 1)
            && itemByIndex[item.index] == nil {
            itemByIndex[item.index] = item
        }

        let items = hasVisibleAnswers.indices.map { offset in
            let index = offset + 1
            guard hasVisibleAnswers[offset] else {
                return VocabularyGradingItem.unanswered(index: index)
            }
            return itemByIndex[index] ?? VocabularyGradingItem.missing(index: index)
        }
        return VocabularyGradingResult(items: items)
    }
}

extension VocabularyGradingItem {
    init(
        index: Int,
        isCorrect: Bool,
        comment: String,
        recognizedText: String
    ) {
        self.index = index
        self.isCorrect = isCorrect
        self.comment = comment
        self.recognizedText = recognizedText
    }

    static func unanswered(index: Int) -> VocabularyGradingItem {
        VocabularyGradingItem(
            index: index,
            isCorrect: false,
            comment: "未作答",
            recognizedText: ""
        )
    }

    static func missing(index: Int) -> VocabularyGradingItem {
        VocabularyGradingItem(
            index: index,
            isCorrect: false,
            comment: "批改结果缺失",
            recognizedText: ""
        )
    }
}
