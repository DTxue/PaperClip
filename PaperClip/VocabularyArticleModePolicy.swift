import Foundation

enum VocabularyArticleViewMode: String, CaseIterable, Identifiable {
    case reading
    case recitation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reading: "阅读"
        case .recitation: "背诵"
        }
    }

    var systemImage: String {
        switch self {
        case .reading: "text.book.closed"
        case .recitation: "mic.circle"
        }
    }
}

enum VocabularyArticleModePolicy {
    static func canSelect(
        _ targetMode: VocabularyArticleViewMode,
        currentMode: VocabularyArticleViewMode,
        isRecitationComplete: Bool
    ) -> Bool {
        if currentMode == .recitation, targetMode == .reading {
            return isRecitationComplete
        }

        return true
    }
}

enum VocabularyArticleGenerationStep: Equatable {
    case generate
    case confirmReplacement
}

enum VocabularyArticleReplacementPolicy {
    static func nextStep(hasExistingArticle: Bool) -> VocabularyArticleGenerationStep {
        hasExistingArticle ? .confirmReplacement : .generate
    }

    static func canCommit(
        hasExistingArticle: Bool,
        replacementConfirmed: Bool,
        isCancelled: Bool,
        isCurrentRequest: Bool
    ) -> Bool {
        guard !isCancelled, isCurrentRequest else { return false }
        return !hasExistingArticle || replacementConfirmed
    }
}

enum VocabularyArticleGenerationCommitPolicy {
    static func canCommit(
        expectedSeriesID: String?,
        currentSeriesID: String?,
        expectedCardFingerprint: String,
        currentCardFingerprint: String,
        replacementConfirmed: Bool,
        isCancelled: Bool,
        isCurrentRequest: Bool
    ) -> Bool {
        guard !isCancelled, isCurrentRequest else { return false }
        guard expectedSeriesID == currentSeriesID else { return false }
        guard expectedCardFingerprint == currentCardFingerprint else { return false }
        return expectedSeriesID == nil || replacementConfirmed
    }
}

enum VocabularyArticleGradePreset: String, CaseIterable, Identifiable {
    case juniorOneTwo
    case juniorThree
    case seniorOneTwo
    case seniorThree

    var id: String { rawValue }

    var title: String {
        switch self {
        case .juniorOneTwo: "初一–初二"
        case .juniorThree: "初三"
        case .seniorOneTwo: "高一–高二"
        case .seniorThree: "高三"
        }
    }

    var learnerDescription: String {
        switch self {
        case .juniorOneTwo: "Chinese Grade 7–8 learners"
        case .juniorThree: "Chinese Grade 9 learners"
        case .seniorOneTwo: "Chinese Grade 10–11 learners"
        case .seniorThree: "Chinese Grade 12 learners"
        }
    }

    var termsPerStory: Int {
        switch self {
        case .juniorOneTwo: 10
        case .juniorThree: 12
        case .seniorOneTwo: 15
        case .seniorThree: 18
        }
    }

    var targetWordRange: ClosedRange<Int> {
        switch self {
        case .juniorOneTwo: 120...160
        case .juniorThree: 150...190
        case .seniorOneTwo: 180...230
        case .seniorThree: 200...260
        }
    }

    var maximumSentenceWords: Int {
        switch self {
        case .juniorOneTwo: 14
        case .juniorThree: 16
        case .seniorOneTwo: 20
        case .seniorThree: 22
        }
    }
}

enum VocabularyArticleGenre: String, CaseIterable, Identifiable, Hashable {
    case campus
    case friendship
    case sports
    case adventure
    case mystery
    case scienceFiction
    case culture
    case nature
    case socialLife
    case growth

    var id: String { rawValue }

    var title: String {
        switch self {
        case .campus: "校园生活"
        case .friendship: "友情成长"
        case .sports: "运动竞技"
        case .adventure: "冒险探索"
        case .mystery: "侦探悬疑"
        case .scienceFiction: "科幻未来"
        case .culture: "历史文化"
        case .nature: "自然环保"
        case .socialLife: "社会生活"
        case .growth: "人物成长"
        }
    }
}

struct VocabularyArticleGenerationConfiguration: Equatable {
    var gradePreset: VocabularyArticleGradePreset
    var preferredStoryCount: Int
    var selectedGenres: Set<VocabularyArticleGenre>
    var customGenre: String

    static let `default` = VocabularyArticleGenerationConfiguration(
        gradePreset: .juniorOneTwo,
        preferredStoryCount: 3,
        selectedGenres: [.campus, .adventure],
        customGenre: ""
    )

    var normalizedCustomGenre: String {
        String(
            customGenre
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(40)
        )
    }

    var isValid: Bool {
        preferredStoryCount > 0 && (!selectedGenres.isEmpty || !normalizedCustomGenre.isEmpty)
    }

    func resolvedStoryCount(cardCount: Int) -> Int {
        guard cardCount > 0 else { return 0 }
        let minimumCount = Int(ceil(
            Double(cardCount) / Double(gradePreset.termsPerStory)
        ))
        return min(cardCount, max(preferredStoryCount, minimumCount))
    }
}

struct VocabularyArticleStoryPlan: Equatable {
    let index: Int
    let totalCount: Int
    let cards: [VocabularyArticleCardInput]
    let theme: String
    let gradePreset: VocabularyArticleGradePreset
    let targetWordRange: ClosedRange<Int>
}

struct VocabularyArticleGenerationPlan: Equatable {
    let stories: [VocabularyArticleStoryPlan]

    static func make(
        cards: [VocabularyArticleCardInput],
        configuration: VocabularyArticleGenerationConfiguration
    ) -> VocabularyArticleGenerationPlan {
        guard !cards.isEmpty else { return VocabularyArticleGenerationPlan(stories: []) }

        let storyCount = configuration.resolvedStoryCount(cardCount: cards.count)
        let themes = resolvedThemes(configuration)
        let baseCardCount = cards.count / storyCount
        let remainder = cards.count % storyCount
        var nextCardIndex = 0
        var stories: [VocabularyArticleStoryPlan] = []
        stories.reserveCapacity(storyCount)

        for storyIndex in 0..<storyCount {
            let cardCount = baseCardCount + (storyIndex < remainder ? 1 : 0)
            let endIndex = nextCardIndex + cardCount
            let storyCards = Array(cards[nextCardIndex..<endIndex])
            nextCardIndex = endIndex
            stories.append(VocabularyArticleStoryPlan(
                index: storyIndex,
                totalCount: storyCount,
                cards: storyCards,
                theme: themes[storyIndex % themes.count],
                gradePreset: configuration.gradePreset,
                targetWordRange: configuration.gradePreset.targetWordRange
            ))
        }

        return VocabularyArticleGenerationPlan(stories: stories)
    }

    private static func resolvedThemes(
        _ configuration: VocabularyArticleGenerationConfiguration
    ) -> [String] {
        var themes = VocabularyArticleGenre.allCases
            .filter(configuration.selectedGenres.contains)
            .map(\.title)
        let customGenre = configuration.normalizedCustomGenre
        if !customGenre.isEmpty {
            themes.append(customGenre)
        }
        return themes.isEmpty ? [VocabularyArticleGenre.campus.title] : themes
    }
}

enum VocabularyArticleQualityPolicy {
    static func revisionReasons(
        articleText: String,
        story: VocabularyArticleStoryPlan
    ) -> [String] {
        let articleWords = VocabularyArticleTextNormalizer.words(from: articleText)
        var reasons: [String] = []
        if articleWords.count < story.targetWordRange.lowerBound {
            reasons.append(
                "Article needs at least \(story.targetWordRange.lowerBound) English words."
            )
        }
        if articleWords.count > story.targetWordRange.upperBound {
            reasons.append(
                "Article exceeds \(story.targetWordRange.upperBound) English words."
            )
        }

        let hasLongSentence = VocabularyArticleSentence.split(articleText).contains { sentence in
            sentence.words.count > story.gradePreset.maximumSentenceWords
        }
        if hasLongSentence {
            reasons.append(
                "Keep every sentence within \(story.gradePreset.maximumSentenceWords) words per sentence."
            )
        }

        let dialogueMarkerCount = articleText.reduce(into: 0) { count, character in
            if character == "\"" || character == "“" || character == "”" {
                count += 1
            }
        }
        if dialogueMarkerCount < 4 {
            reasons.append("Include at least two lines of natural dialogue in quotation marks.")
        }

        for card in story.cards {
            let termWords = VocabularyArticleTextNormalizer.words(from: card.term)
            guard !termWords.isEmpty,
                  !contains(termWords, in: articleWords)
            else { continue }
            reasons.append("Missing target term: \(card.term)")
        }
        return reasons
    }

    private static func contains(_ target: [String], in words: [String]) -> Bool {
        guard target.count <= words.count else { return false }
        if target.count == 1 { return words.contains(target[0]) }

        for startIndex in 0...(words.count - target.count) {
            if Array(words[startIndex..<(startIndex + target.count)]) == target {
                return true
            }
        }
        return false
    }
}

enum VocabularyArticleQualityError: LocalizedError {
    case validationFailed([String])

    var errorDescription: String? {
        switch self {
        case let .validationFailed(reasons):
            "AI 两次生成的故事仍未满足篇幅或词条覆盖要求：\(reasons.joined(separator: "；"))"
        }
    }
}
