import Foundation

@main
struct VocabularyContextPracticeTests {
    static func main() throws {
        try testBuildsLessonByStableCardIndex()
        testRejectsUnexpectedGeneratedIndexes()
        testRejectsUnanswerableContext()
        testChecksOnlyContextuallyValidAnswers()
        testPromptFixesMeaningAndClozeContract()
        testRejectsClozeThatChangesTheSourceSentence()
        try testAcceptsOnlyUserApprovedSourceWordForms()
        testRejectsAnswerUnrelatedToSourceTerm()
        testRejectsUnapprovedGeneratedInflection()
        testEnforcesLocalGenerationConstraints()
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
                cloze: "Mia felt ___ when her classmate returned the lost notebook.",
                answer: "grateful",
                acceptedAnswers: ["grateful"],
                collocation: "feel grateful",
                usageTip: "常用于 be 或 feel 后。"
            ),
            .init(
                index: 1,
                sentence: "Leo did not hesitate when he heard a child call for help.",
                cloze: "Leo did not ___ when he heard a child call for help.",
                answer: "hesitate",
                acceptedAnswers: ["hesitate"],
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
        expect(lesson.items.map(\.answer) == ["hesitate", "grateful"])
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
            cloze: "Leo did not ___ when he heard a child call for help.",
            answer: "hesitate",
            acceptedAnswers: ["hesitate"],
            collocation: "hesitate to do something",
            usageTip: "后接不定式。"
        )
        let extraItem = VocabularyContextGenerationResult.Item(
            index: 2,
            sentence: "This item does not belong to a source card.",
            cloze: "This item does not ___ to a source card.",
            answer: "belong",
            acceptedAnswers: ["belong"],
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
            cloze: "Leo paused before opening the door.",
            answer: "hesitate",
            acceptedAnswers: [],
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
            expect(error.issues.contains { $0.contains("遮挡") })
            expect(error.issues.contains { $0.contains("答案") })
        } catch {
            fatalError("Unexpected error: \(error)")
        }
    }

    private static func testChecksOnlyContextuallyValidAnswers() {
        let item = VocabularyContextPracticeItem(
            cardID: UUID(),
            term: "hesitate",
            definition: "犹豫",
            sentence: "Leo hesitated before opening the door.",
            cloze: "Leo ___ before opening the door.",
            answer: "hesitated",
            acceptedAnswers: ["hesitated"],
            collocation: "hesitate before doing something",
            usageTip: ""
        )

        expect(VocabularyContextPracticeAnswerChecker.isCorrect(" Hesitated. ", for: item))
        expect(!VocabularyContextPracticeAnswerChecker.isCorrect("hesitate", for: item))
        expect(!VocabularyContextPracticeAnswerChecker.isCorrect("", for: item))
    }

    private static func testPromptFixesMeaningAndClozeContract() {
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
        expect(prompt.contains("exactly one ___"))
        expect(prompt.contains("high-constraint"))
        expect(prompt.contains(#""acceptedAnswers":["..."]"#))
    }

    private static func testRejectsClozeThatChangesTheSourceSentence() {
        let card = VocabularyContextCardInput(
            cardID: UUID(),
            term: "hesitate",
            definition: "犹豫",
            englishDefinition: "",
            partOfSpeech: "verb",
            example: "",
            alternativeAnswers: []
        )
        let inconsistentItem = VocabularyContextGenerationResult.Item(
            index: 1,
            sentence: "Leo did not hesitate before opening the door.",
            cloze: "Leo did not ___ before closing the door.",
            answer: "hesitate",
            acceptedAnswers: ["hesitate"],
            collocation: "hesitate before doing something",
            usageTip: ""
        )

        do {
            _ = try VocabularyContextPracticeBuilder.build(
                cards: [card],
                generated: .init(items: [inconsistentItem])
            )
            fatalError("A cloze that changes the source sentence must be rejected")
        } catch let error as VocabularyContextPracticeValidationError {
            expect(error.issues.contains { $0.contains("完整句") })
        } catch {
            fatalError("Unexpected error: \(error)")
        }
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
                    cloze: "Leo ___ before opening the door.",
                    answer: "hesitated",
                    acceptedAnswers: ["hesitated", "paused"],
                    collocation: "hesitate before doing something",
                    usageTip: "这里用过去式表示已经发生。"
                )
            ])
        )

        let item = lesson.items[0]
        expect(item.acceptedAnswers == ["hesitated"])
        expect(VocabularyContextPracticeAnswerChecker.isCorrect("hesitated", for: item))
        expect(!VocabularyContextPracticeAnswerChecker.isCorrect("paused", for: item))
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
                        cloze: "Leo ___ before opening the door.",
                        answer: "paused",
                        acceptedAnswers: ["paused"],
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
                        cloze: "Mia is ___ the window.",
                        answer: "openning",
                        acceptedAnswers: ["openning"],
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
                        cloze: "Leo did not ___ before opening the classroom door.",
                        answer: "hesitate",
                        acceptedAnswers: ["hesitate"],
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
