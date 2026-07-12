import Foundation

@main
struct VocabularyArticleModePolicyTests {
    static func main() {
        testGenerationPlanCoversEveryCardWithoutOverloadingStories()
        testSeniorPresetControlsStorySizeAndLength()
        testCustomGenreCanDriveAStorySeries()
        testQualityPolicyRequestsRevisionForLongOrIncompleteStories()

        expect(
            VocabularyArticleModePolicy.canSelect(
                .recitation,
                currentMode: .reading,
                isRecitationComplete: false
            ),
            "reading should be able to enter recitation"
        )

        expect(
            !VocabularyArticleModePolicy.canSelect(
                .reading,
                currentMode: .recitation,
                isRecitationComplete: false
            ),
            "unfinished recitation must not switch back to reading"
        )

        expect(
            VocabularyArticleModePolicy.canSelect(
                .reading,
                currentMode: .recitation,
                isRecitationComplete: true
            ),
            "completed recitation may return to reading"
        )

        expect(
            VocabularyArticleReplacementPolicy.nextStep(hasExistingArticle: false) == .generate,
            "first generation should start directly"
        )
        expect(
            VocabularyArticleReplacementPolicy.nextStep(hasExistingArticle: true) == .confirmReplacement,
            "an existing article must require replacement confirmation"
        )
        expect(
            !VocabularyArticleReplacementPolicy.canCommit(
                hasExistingArticle: true,
                replacementConfirmed: false,
                isCancelled: false,
                isCurrentRequest: true
            ),
            "an unconfirmed result must not replace an existing article"
        )
        expect(
            VocabularyArticleReplacementPolicy.canCommit(
                hasExistingArticle: true,
                replacementConfirmed: true,
                isCancelled: false,
                isCurrentRequest: true
            ),
            "a confirmed replacement may be committed"
        )
        expect(
            !VocabularyArticleReplacementPolicy.canCommit(
                hasExistingArticle: false,
                replacementConfirmed: false,
                isCancelled: true,
                isCurrentRequest: true
            ),
            "a cancelled generation must never be committed"
        )
        expect(
            !VocabularyArticleReplacementPolicy.canCommit(
                hasExistingArticle: false,
                replacementConfirmed: false,
                isCancelled: false,
                isCurrentRequest: false
            ),
            "a stale generation must never be committed"
        )

        print("VocabularyArticleModePolicyTests: generation and mode policies passed")
    }

    private static func testGenerationPlanCoversEveryCardWithoutOverloadingStories() {
        let cards = (1...25).map {
            VocabularyArticleCardInput(term: "term\($0)", definition: "definition\($0)")
        }
        let configuration = VocabularyArticleGenerationConfiguration(
            gradePreset: .juniorOneTwo,
            preferredStoryCount: 2,
            selectedGenres: [.campus, .mystery],
            customGenre: ""
        )

        let plan = VocabularyArticleGenerationPlan.make(
            cards: cards,
            configuration: configuration
        )

        expect(plan.stories.count == 3, "the plan should raise the story count to keep stories short")
        expect(
            plan.stories.flatMap(\.cards).map(\.term) == cards.map(\.term),
            "the plan should cover every card exactly once"
        )
        expect(
            plan.stories.allSatisfy { $0.cards.count <= 10 },
            "junior stories should contain at most ten target terms"
        )
        expect(
            plan.stories.map(\.theme) == ["校园生活", "侦探悬疑", "校园生活"],
            "selected genres should rotate across the series"
        )
    }

    private static func testSeniorPresetControlsStorySizeAndLength() {
        let cards = (1...31).map {
            VocabularyArticleCardInput(term: "term\($0)", definition: "definition\($0)")
        }
        let plan = VocabularyArticleGenerationPlan.make(
            cards: cards,
            configuration: VocabularyArticleGenerationConfiguration(
                gradePreset: .seniorThree,
                preferredStoryCount: 1,
                selectedGenres: [.scienceFiction],
                customGenre: ""
            )
        )

        expect(plan.stories.count == 2, "senior-three stories should contain at most eighteen terms")
        expect(
            plan.stories.allSatisfy { $0.targetWordRange == 200...260 },
            "senior-three stories should use the high-school reading length preset"
        )
    }

    private static func testCustomGenreCanDriveAStorySeries() {
        let cards = (1...4).map {
            VocabularyArticleCardInput(term: "term\($0)", definition: "definition\($0)")
        }
        let configuration = VocabularyArticleGenerationConfiguration(
            gradePreset: .juniorThree,
            preferredStoryCount: 2,
            selectedGenres: [],
            customGenre: "  校园机器人比赛  "
        )
        let plan = VocabularyArticleGenerationPlan.make(
            cards: cards,
            configuration: configuration
        )

        expect(configuration.isValid, "a non-empty custom genre should make the configuration valid")
        expect(
            plan.stories.map(\.theme) == ["校园机器人比赛", "校园机器人比赛"],
            "a custom genre should be trimmed and applied to every requested story"
        )
    }

    private static func testQualityPolicyRequestsRevisionForLongOrIncompleteStories() {
        let story = VocabularyArticleStoryPlan(
            index: 0,
            totalCount: 1,
            cards: [
                VocabularyArticleCardInput(term: "solve", definition: "解决"),
                VocabularyArticleCardInput(term: "clue", definition: "线索")
            ],
            theme: "侦探悬疑",
            gradePreset: .juniorOneTwo,
            targetWordRange: 120...160
        )
        let longStory = Array(repeating: "ordinary", count: 161).joined(separator: " ")
        let reasons = VocabularyArticleQualityPolicy.revisionReasons(
            articleText: longStory,
            story: story
        )

        expect(reasons.contains(where: { $0.contains("160") }), "overlong stories should be revised")
        expect(reasons.contains(where: { $0.contains("solve") }), "missing target terms should be revised")
        expect(reasons.contains(where: { $0.contains("clue") }), "every missing target term should be reported")
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError(message, file: file, line: line)
        }
    }
}
