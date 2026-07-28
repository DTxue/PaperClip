import Foundation

@main
struct VocabularyContextPracticeTests {
    static func main() throws {
        try testBuildsLessonByStableCardIndex()
        testRejectsUnexpectedGeneratedIndexes()
        testRejectsUnanswerableContext()
        testPromptFixesMeaningAndContextContract()
        try testAcceptsOnlyUserApprovedSourceWordForms()
        testRejectsAnswerUnrelatedToSourceTerm()
        testRejectsUnapprovedGeneratedInflection()
        testEnforcesLocalGenerationConstraints()
        try testCacheReusesOnlyMatchingIdentity()
        testSourceFingerprintChangesWithCardContent()
        print("VocabularyContextPracticeTests: 10 passed")
    }

    private static func testBuildsLessonByStableCardIndex() throws {
        let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let secondID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let cards = [
            VocabularyContextCardInput(
                cardID: firstID,
                term: "hesitate",
                definition: "犹豫",
                englishDefinition: "to pause before doing something",
                partOfSpeech: "verb",
                example: "",
                alternativeAnswers: []
            ),
            VocabularyContextCardInput(
                cardID: secondID,
                term: "grateful",
                definition: "感激的",
                englishDefinition: "feeling thankful",
                partOfSpeech: "adjective",
                example: "",
                alternativeAnswers: []
            )
        ]
        let generated = VocabularyContextGenerationResult(items: [
            .init(
                index: 2,
                sentence: "Mia felt grateful when her classmate returned the lost notebook.",
                answer: "grateful",
                collocation: "feel grateful",
                usageTip: "常用于 be 或 feel 后。"
            ),
            .init(
                index: 1,
                sentence: "Leo did not hesitate when he heard a child call for help.",
                answer: "hesitate",
                collocation: "hesitate to do something",
                usageTip: "后接不定式说明犹豫做某事。"
            )
        ])

        let lesson = try VocabularyContextPracticeBuilder.build(
            cards: cards,
            generated: generated
        )

        expect(lesson.items.map(\.cardID) == [firstID, secondID])
        expect(lesson.items.map(\.term) == ["hesitate", "grateful"])
        expect(lesson.items.map(\.collocation) == [
            "hesitate to do something",
            "feel grateful"
        ])
    }

    private static func testRejectsUnexpectedGeneratedIndexes() {
        let card = VocabularyContextCardInput(
            cardID: UUID(),
            term: "hesitate",
            definition: "犹豫",
            englishDefinition: "",
            partOfSpeech: "verb",
            example: "",
            alternativeAnswers: []
        )
        let validItem = VocabularyContextGenerationResult.Item(
            index: 1,
            sentence: "Leo did not hesitate when he heard a child call for help.",
            answer: "hesitate",
            collocation: "hesitate to do something",
            usageTip: "后接不定式。"
        )
        let extraItem = VocabularyContextGenerationResult.Item(
            index: 2,
            sentence: "This item does not belong to a source card.",
            answer: "belong",
            collocation: "belong to",
            usageTip: ""
        )

        do {
            _ = try VocabularyContextPracticeBuilder.build(
                cards: [card],
                generated: .init(items: [validItem, extraItem])
            )
            fatalError("Unexpected generated indexes must be rejected")
        } catch let error as VocabularyContextPracticeValidationError {
            expect(error.issues.contains { $0.contains("索引") })
        } catch {
            fatalError("Unexpected error: \(error)")
        }
    }

    private static func testRejectsUnanswerableContext() {
        let card = VocabularyContextCardInput(
            cardID: UUID(),
            term: "hesitate",
            definition: "犹豫",
            englishDefinition: "",
            partOfSpeech: "verb",
            example: "",
            alternativeAnswers: []
        )
        let invalidItem = VocabularyContextGenerationResult.Item(
            index: 1,
            sentence: "Leo paused before opening the door.",
            answer: "hesitate",
            collocation: "",
            usageTip: ""
        )

        do {
            _ = try VocabularyContextPracticeBuilder.build(
                cards: [card],
                generated: .init(items: [invalidItem])
            )
            fatalError("An unanswerable context must be rejected")
        } catch let error as VocabularyContextPracticeValidationError {
            expect(error.issues.contains { $0.contains("答案") })
        } catch {
            fatalError("Unexpected error: \(error)")
        }
    }

    private static func testPromptFixesMeaningAndContextContract() {
        let card = VocabularyContextCardInput(
            cardID: UUID(),
            term: "conduct",
            definition: "实施；进行",
            englishDefinition: "to organize and do an activity",
            partOfSpeech: "verb",
            example: "Students conduct an experiment.",
            alternativeAnswers: []
        )

        let prompt = VocabularyContextPracticePrompt.make(
            cards: [card],
            configuration: .init(
                learnerDescription: "Chinese Grade 7–8 learners",
                maximumSentenceWords: 14
            )
        )

        expect(prompt.contains("Chinese Grade 7–8 learners"))
        expect(prompt.contains("no more than 14 words"))
        expect(prompt.contains("definition: 实施；进行"))
        expect(prompt.contains("context-learning examples"))
        expect(prompt.contains("high-constraint"))
        expect(prompt.contains(#""answer":"...""#))
        expect(!prompt.contains("cloze"))
        expect(!prompt.contains("acceptedAnswers"))
    }

    private static func testAcceptsOnlyUserApprovedSourceWordForms() throws {
        let card = VocabularyContextCardInput(
            cardID: UUID(),
            term: "hesitate",
            definition: "犹豫",
            englishDefinition: "",
            partOfSpeech: "verb",
            example: "",
            alternativeAnswers: ["hesitated"]
        )
        let lesson = try VocabularyContextPracticeBuilder.build(
            cards: [card],
            generated: .init(items: [
                .init(
                    index: 1,
                    sentence: "Leo hesitated before opening the door.",
                    answer: "hesitated",
                    collocation: "hesitate before doing something",
                    usageTip: "这里用过去式表示已经发生。"
                )
            ])
        )

        let item = lesson.items[0]
        expect(item.sentence == "Leo hesitated before opening the door.")
        expect(item.collocation == "hesitate before doing something")
    }

    private static func testRejectsAnswerUnrelatedToSourceTerm() {
        let card = VocabularyContextCardInput(
            cardID: UUID(),
            term: "hesitate",
            definition: "犹豫",
            englishDefinition: "",
            partOfSpeech: "verb",
            example: "",
            alternativeAnswers: []
        )

        do {
            _ = try VocabularyContextPracticeBuilder.build(
                cards: [card],
                generated: .init(items: [
                    .init(
                        index: 1,
                        sentence: "Leo paused before opening the door.",
                        answer: "paused",
                        collocation: "pause before doing something",
                        usageTip: "这个句子表达动作前的停顿。"
                    )
                ])
            )
            fatalError("An unrelated synonym must not update source-term memory")
        } catch let error as VocabularyContextPracticeValidationError {
            expect(error.issues.contains { $0.contains("源词") })
        } catch {
            fatalError("Unexpected error: \(error)")
        }
    }

    private static func testRejectsUnapprovedGeneratedInflection() {
        let card = VocabularyContextCardInput(
            cardID: UUID(),
            term: "open",
            definition: "打开",
            englishDefinition: "",
            partOfSpeech: "verb",
            example: "",
            alternativeAnswers: []
        )

        do {
            _ = try VocabularyContextPracticeBuilder.build(
                cards: [card],
                generated: .init(items: [
                    .init(
                        index: 1,
                        sentence: "Mia is openning the window.",
                        answer: "openning",
                        collocation: "open the window",
                        usageTip: "答案必须来自词卡认可的形式。"
                    )
                ])
            )
            fatalError("A model-invented inflection must not be trusted")
        } catch let error as VocabularyContextPracticeValidationError {
            expect(error.issues.contains { $0.contains("词卡") })
        } catch {
            fatalError("Unexpected error: \(error)")
        }
    }

    private static func testEnforcesLocalGenerationConstraints() {
        let card = VocabularyContextCardInput(
            cardID: UUID(),
            term: "hesitate",
            definition: "犹豫",
            englishDefinition: "",
            partOfSpeech: "verb",
            example: "",
            alternativeAnswers: []
        )

        do {
            _ = try VocabularyContextPracticeBuilder.build(
                cards: [card],
                generated: .init(items: [
                    .init(
                        index: 1,
                        sentence: "Leo did not hesitate before opening the classroom door.",
                        answer: "hesitate",
                        collocation: "hesitate before doing something",
                        usageTip: "Use it before an infinitive."
                    )
                ]),
                maximumSentenceWords: 6
            )
            fatalError("Overlong context without a Chinese tip must be rejected")
        } catch let error as VocabularyContextPracticeValidationError {
            expect(error.issues.contains { $0.contains("词数") })
            expect(error.issues.contains { $0.contains("中文") })
        } catch {
            fatalError("Unexpected error: \(error)")
        }
    }

    private static func testCacheReusesOnlyMatchingIdentity() throws {
        let suiteName = "VocabularyContextPracticeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = VocabularyContextPracticeCacheStore(
            defaults: defaults,
            keyPrefix: "context-practice-test"
        )
        let deckID = UUID()
        let cardID = UUID()
        let identity = VocabularyContextPracticeCacheIdentity(
            deckID: deckID,
            sourceFingerprint: "cards-v1",
            gradePresetRawValue: "juniorOneTwo",
            maximumCardCount: 6
        )
        let lesson = VocabularyContextPracticeLesson(items: [
            VocabularyContextPracticeItem(
                cardID: cardID,
                term: "hesitate",
                definition: "犹豫",
                sentence: "Leo did not hesitate before opening the door.",
                collocation: "hesitate before doing something",
                usageTip: "后接不定式。"
            )
        ])

        try store.save(lesson, identity: identity)

        expect(store.load(identity: identity) == lesson)
        expect(store.load(identity: .init(
            deckID: deckID,
            sourceFingerprint: "cards-v2",
            gradePresetRawValue: "juniorOneTwo",
            maximumCardCount: 6
        )) == nil)
        expect(store.load(identity: .init(
            deckID: deckID,
            sourceFingerprint: "cards-v1",
            gradePresetRawValue: "seniorOneTwo",
            maximumCardCount: 6
        )) == nil)

        let seniorIdentity = VocabularyContextPracticeCacheIdentity(
            deckID: deckID,
            sourceFingerprint: "cards-v1",
            gradePresetRawValue: "seniorOneTwo",
            maximumCardCount: 6
        )
        try store.save(lesson, identity: seniorIdentity)

        expect(store.load(identity: identity) == lesson)
        expect(store.load(identity: seniorIdentity) == lesson)
    }

    private static func testSourceFingerprintChangesWithCardContent() {
        let cardID = UUID()
        let original = VocabularyContextCardInput(
            cardID: cardID,
            term: "hesitate",
            definition: "犹豫",
            englishDefinition: "pause before doing something",
            partOfSpeech: "verb",
            example: "",
            alternativeAnswers: []
        )
        let edited = VocabularyContextCardInput(
            cardID: cardID,
            term: "hesitate",
            definition: "迟疑",
            englishDefinition: "pause before doing something",
            partOfSpeech: "verb",
            example: "",
            alternativeAnswers: []
        )

        let originalFingerprint = VocabularyContextPracticeSourceFingerprint.make(
            cards: [original]
        )
        expect(
            originalFingerprint
                == VocabularyContextPracticeSourceFingerprint.make(cards: [original])
        )
        expect(
            originalFingerprint
                != VocabularyContextPracticeSourceFingerprint.make(cards: [edited])
        )
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError("Expectation failed", file: file, line: line)
        }
    }
}
