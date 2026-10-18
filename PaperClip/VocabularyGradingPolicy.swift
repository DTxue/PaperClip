import Foundation

enum VocabularyAnswerMatchPolicy: Equatable {
    case spelling
    case chineseDictation
    case englishDefinition

    func normalized(_ value: String) -> String {
        switch self {
        case .chineseDictation:
            let punctuationNormalized = value
                .replacingOccurrences(of: "……", with: "…")
                .replacingOccurrences(of: "...", with: "…")
            return punctuationNormalized.reduce(into: "") { normalized, character in
                guard !character.isWhitespace else { return }
                if let equivalent = Self.chinesePunctuationEquivalents[character] {
                    normalized.append(equivalent)
                } else {
                    normalized.append(character)
                }
            }
        case .spelling:
            let folded = value.folding(
                options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
            return folded.reduce(into: "") { normalized, character in
                if character.isLetter || character.isNumber {
                    normalized.append(character)
                } else if Self.apostrophes.contains(character) {
                    normalized.append("'")
                }
            }
        case .englishDefinition:
            let trimmed = value
                .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            return trimmed.lowercased(with: Locale(identifier: "en_US_POSIX"))
        }
    }

    private static let apostrophes: Set<Character> = ["'", "’", "‘", "ʼ", "＇"]

    private static let chinesePunctuationEquivalents: [Character: Character] = [
        "，": ",", "﹐": ",",
        "。": ".", "．": ".", "﹒": ".",
        "？": "?", "﹖": "?", "！": "!", "﹗": "!",
        "：": ":", "﹕": ":", "；": ";", "﹔": ";",
        "（": "(", "）": ")",
        "【": "[", "】": "]",
        "“": "\"", "”": "\"", "「": "\"", "」": "\"",
        "《": "\"", "》": "\"", "〈": "\"", "〉": "\"",
        "‘": "'", "’": "'", "＇": "'",
        "…": "…"
    ]
}

enum VocabularyGradingPolicy {
    static let suspectedPunctuationCommentPrefix = "疑似标点识别差异（不计错）"

    static func validated(
        _ result: VocabularyGradingResult,
        expectedAnswers: [String],
        hasVisibleAnswers: [Bool],
        matchPolicy: VocabularyAnswerMatchPolicy = .spelling
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
            guard expectedAnswers.indices.contains(offset) else {
                return VocabularyGradingItem.missingExpectedAnswer(index: index)
            }
            guard let item = itemByIndex[index] else {
                return VocabularyGradingItem.missing(index: index)
            }
            return validated(
                item,
                expectedAnswer: expectedAnswers[offset],
                matchPolicy: matchPolicy
            )
        }
        return VocabularyGradingResult(items: items)
    }

    private static func validated(
        _ item: VocabularyGradingItem,
        expectedAnswer: String,
        matchPolicy: VocabularyAnswerMatchPolicy
    ) -> VocabularyGradingItem {
        let recognizedText = item.recognizedText
        guard !recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return VocabularyGradingItem(
                index: item.index,
                isCorrect: false,
                comment: "未识别到答案",
                recognizedText: ""
            )
        }

        let normalizedRecognized = matchPolicy.normalized(recognizedText)
        let normalizedExpected = matchPolicy.normalized(expectedAnswer)
        let matches = normalizedRecognized == normalizedExpected
        let chineseEdits = matchPolicy == .chineseDictation && !matches
            ? chineseCharacterEdits(
                recognized: Array(normalizedRecognized),
                expected: Array(normalizedExpected)
            )
            : []
        let isPunctuationOnlyDifference = matchPolicy == .chineseDictation
            && !chineseEdits.isEmpty
            && chineseEdits.allSatisfy(\.isPunctuationRelated)
        let isCorrect = matches || isPunctuationOnlyDifference
        let comment: String
        if matches {
            comment = "正确"
        } else if matchPolicy == .chineseDictation {
            comment = chineseMismatchComment(chineseEdits)
        } else {
            comment = mismatchComment(
                recognizedText: recognizedText,
                expectedAnswer: expectedAnswer,
                matchPolicy: matchPolicy
            )
        }
        return VocabularyGradingItem(
            index: item.index,
            isCorrect: isCorrect,
            comment: comment,
            recognizedText: recognizedText
        )
    }

    private static func mismatchComment(
        recognizedText: String,
        expectedAnswer: String,
        matchPolicy: VocabularyAnswerMatchPolicy
    ) -> String {
        guard matchPolicy == .chineseDictation else {
            return "答案应为 \(expectedAnswer)"
        }

        let recognized = Array(matchPolicy.normalized(recognizedText))
        let expected = Array(matchPolicy.normalized(expectedAnswer))
        let edits = chineseCharacterEdits(recognized: recognized, expected: expected)
        guard !edits.isEmpty else { return "答案应为 \(expectedAnswer)" }
        return edits.map(\.description).joined(separator: "\n")
    }

    private enum ChineseCharacterEdit {
        case substitution(position: Int, recognized: Character, expected: Character)
        case missing(position: Int, expected: Character)
        case extra(position: Int, recognized: Character)

        var description: String {
            switch self {
            case let .substitution(position, recognized, expected):
                "第\(position)处：识别为“\(recognized)”，应为“\(expected)”"
            case let .missing(position, expected):
                "第\(position)处漏写，应为“\(expected)”"
            case let .extra(position, recognized):
                "第\(position)处多出“\(recognized)”"
            }
        }

        var isPunctuationRelated: Bool {
            switch self {
            case let .substitution(_, recognized, expected):
                recognized.isPunctuationMark || expected.isPunctuationMark
            case let .missing(_, expected):
                expected.isPunctuationMark
            case let .extra(_, recognized):
                recognized.isPunctuationMark
            }
        }

        var suspectedPunctuationDescription: String {
            switch self {
            case let .substitution(position, recognized, expected):
                "疑似第\(position)处标点识别差异：识别为“\(recognized)”，参考为“\(expected)”"
            case let .missing(position, expected):
                "疑似第\(position)处标点未识别：参考为“\(expected)”"
            case let .extra(position, recognized):
                "疑似第\(position)处多识别标点“\(recognized)”"
            }
        }
    }

    private static func chineseMismatchComment(_ edits: [ChineseCharacterEdit]) -> String {
        guard !edits.isEmpty else { return "识别结果与答案不一致" }
        let descriptions = edits.map { edit in
            edit.isPunctuationRelated ? edit.suspectedPunctuationDescription : edit.description
        }
        if edits.allSatisfy(\.isPunctuationRelated) {
            return ([suspectedPunctuationCommentPrefix] + descriptions).joined(separator: "\n")
        }
        return descriptions.joined(separator: "\n")
    }

    private static func chineseCharacterEdits(
        recognized: [Character],
        expected: [Character]
    ) -> [ChineseCharacterEdit] {
        let recognizedCount = recognized.count
        let expectedCount = expected.count
        var distance = Array(
            repeating: Array(repeating: 0, count: expectedCount + 1),
            count: recognizedCount + 1
        )

        for recognizedIndex in 0...recognizedCount {
            distance[recognizedIndex][0] = recognizedIndex
        }
        for expectedIndex in 0...expectedCount {
            distance[0][expectedIndex] = expectedIndex
        }

        if recognizedCount > 0, expectedCount > 0 {
            for recognizedIndex in 1...recognizedCount {
                for expectedIndex in 1...expectedCount {
                    if recognized[recognizedIndex - 1] == expected[expectedIndex - 1] {
                        distance[recognizedIndex][expectedIndex] = distance[recognizedIndex - 1][expectedIndex - 1]
                    } else {
                        distance[recognizedIndex][expectedIndex] = min(
                            distance[recognizedIndex - 1][expectedIndex - 1] + 1,
                            min(
                                distance[recognizedIndex - 1][expectedIndex] + 1,
                                distance[recognizedIndex][expectedIndex - 1] + 1
                            )
                        )
                    }
                }
            }
        }

        var edits: [ChineseCharacterEdit] = []
        var recognizedIndex = recognizedCount
        var expectedIndex = expectedCount
        while recognizedIndex > 0 || expectedIndex > 0 {
            if recognizedIndex > 0,
               expectedIndex > 0,
               recognized[recognizedIndex - 1] == expected[expectedIndex - 1],
               distance[recognizedIndex][expectedIndex] == distance[recognizedIndex - 1][expectedIndex - 1] {
                recognizedIndex -= 1
                expectedIndex -= 1
                continue
            }

            if recognizedIndex > 0,
               expectedIndex > 0,
               distance[recognizedIndex][expectedIndex] == distance[recognizedIndex - 1][expectedIndex - 1] + 1 {
                edits.append(.substitution(
                    position: expectedIndex,
                    recognized: recognized[recognizedIndex - 1],
                    expected: expected[expectedIndex - 1]
                ))
                recognizedIndex -= 1
                expectedIndex -= 1
            } else if recognizedIndex > 0,
                      distance[recognizedIndex][expectedIndex] == distance[recognizedIndex - 1][expectedIndex] + 1 {
                edits.append(.extra(
                    position: expectedIndex + 1,
                    recognized: recognized[recognizedIndex - 1]
                ))
                recognizedIndex -= 1
            } else if expectedIndex > 0 {
                edits.append(.missing(
                    position: expectedIndex,
                    expected: expected[expectedIndex - 1]
                ))
                expectedIndex -= 1
            }
        }

        return edits.reversed()
    }
}

private extension Character {
    var isPunctuationMark: Bool {
        !unicodeScalars.isEmpty
            && unicodeScalars.allSatisfy(CharacterSet.punctuationCharacters.contains)
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

    static func missingExpectedAnswer(index: Int) -> VocabularyGradingItem {
        VocabularyGradingItem(
            index: index,
            isCorrect: false,
            comment: "标准答案缺失",
            recognizedText: ""
        )
    }
}
