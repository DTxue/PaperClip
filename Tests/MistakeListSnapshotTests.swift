import Foundation

func assert(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fatalError(message)
    }
}

func makeRow(
    id: UUID = UUID(),
    subject: String = Subject.math.rawValue,
    status: String = MasteryStatus.unmastered.rawValue,
    tagsText: String = "",
    note: String = "",
    recognizedText: String = "",
    questionType: String = "",
    correctAnswer: String = "",
    sourceDocumentTitle: String = "",
    createdAt: Date = Date(timeIntervalSince1970: 0)
) -> MistakeCardRowData {
    MistakeCardRowData(
        id: id,
        imageFileName: "card.png",
        grade: Grade.grade7.rawValue,
        semester: Semester.first.rawValue,
        subject: subject,
        tagsText: tagsText,
        status: status,
        note: note,
        createdAt: createdAt,
        recognitionStatus: RecognitionStatus.completed.rawValue,
        recognizedText: recognizedText,
        questionType: questionType,
        correctAnswer: correctAnswer,
        sourceDocumentTitle: sourceDocumentTitle
    )
}

@main
struct MistakeListSnapshotTests {
    static func main() {
        let rows = [
            makeRow(
                tagsText: "函数, 一次函数, 函数",
                recognizedText: "选择正确答案",
                questionType: "选择题",
                sourceDocumentTitle: "期中"
            ),
            makeRow(
                subject: Subject.physics.rawValue,
                status: MasteryStatus.mastered.rawValue,
                tagsText: "力学",
                recognizedText: "计算速度",
                questionType: "计算题",
                sourceDocumentTitle: "周测"
            )
        ]

        let whitespace = MistakeListSnapshot(
            cards: rows,
            searchText: "   ",
            selectedStatus: "",
            selectedQuestionType: "",
            selectedTag: "",
            selectedSource: ""
        )
        assert(whitespace.filteredCards.count == 2, "whitespace search should not filter cards")
        assert(whitespace.topTags.map(\.tag) == ["一次函数", "函数", "力学"], "top tags should be stable and unique per card")
        assert(whitespace.topTags.allSatisfy { $0.count == 1 }, "duplicate tags in one card should not inflate counts")

        let typeFiltered = MistakeListSnapshot(
            cards: rows,
            searchText: "",
            selectedStatus: "",
            selectedQuestionType: QuestionType.choice.rawValue,
            selectedTag: "",
            selectedSource: ""
        )
        assert(typeFiltered.filteredCards.count == 1, "question type filter should match one card")
        assert(typeFiltered.filteredCards[0].recognizedText == "选择正确答案", "question type filter should keep matching card")
        assert(MistakeTagParser.parse("函数， 一次函数\n图像,函数") == ["函数", "一次函数", "图像"], "tag parser should support Chinese comma and newline")

        let tagFiltered = MistakeListSnapshot(
            cards: rows,
            searchText: "",
            selectedStatus: "",
            selectedQuestionType: "",
            selectedTag: "力学",
            selectedSource: ""
        )
        assert(tagFiltered.filteredCards.count == 1, "tag filter should match one card")
        assert(tagFiltered.masterySummary.total == 2, "mastery summary should use all cards")
        assert(MistakeTagParser.serialize([" 函数 ", "函数", "", "力学"]) == "函数,力学", "tag serialization should normalize and deduplicate")
        assert(MistakeTagParser.appending("函数，图像\n坐标", to: ["函数", "一次函数"]) == ["函数", "一次函数", "图像", "坐标"], "tag appending should preserve existing order and append only new tags")
        assert(MistakeTagDisplay.preview(["函数", "一次函数", "图像"], limit: 2) == "函数 · 一次函数", "tag preview should limit and use compact separator")
        assert(MistakeTagDisplay.accessibilityList(["函数", "一次函数"]) == "函数、一次函数", "tag accessibility list should use spoken Chinese separator")
        assert(rows[0].tagPreviewText == "函数 · 一次函数", "row tag preview should reuse shared display helper")
        assert(rows[0].metadataText == "七年级 · 上学期 · 选择题 · 函数", "row metadata should reuse one display rule")
        var tagCounts: [String: Int] = [:]
        MistakeTagSummary.add(["b", "a"], to: &tagCounts)
        MistakeTagSummary.add(["b", "c"], to: &tagCounts)
        let topTwoTags = MistakeTagSummary.topTags(from: tagCounts, limit: 2)
        assert(topTwoTags.map(\.tag) == ["b", "a"], "tag summary should rank by count then name")
        assert(topTwoTags.map(\.count) == [2, 1], "tag summary should preserve counts and limit results")

        let empty = MistakeListSnapshot(
            cards: [],
            searchText: "",
            selectedStatus: "",
            selectedQuestionType: "",
            selectedTag: "",
            selectedSource: ""
        )
        assert(empty.emptyState.title == "还没有错题", "empty list should use initial empty state")

        let missingSource = MistakeListSnapshot(
            cards: rows,
            searchText: "",
            selectedStatus: "",
            selectedQuestionType: "",
            selectedTag: "",
            selectedSource: "不存在的试卷"
        )
        assert(
            missingSource.emptyState.description == "试卷「不存在的试卷」下暂无符合条件的错题。",
            "source empty state should mention source"
        )

        let missingTag = MistakeListSnapshot(
            cards: rows,
            searchText: "",
            selectedStatus: "",
            selectedQuestionType: "",
            selectedTag: "不存在的知识点",
            selectedSource: ""
        )
        assert(
            missingTag.emptyState.description == "知识点「不存在的知识点」下暂无错题。",
            "tag empty state should mention tag"
        )

        let paperSelectionIDs = PaperSelectionSnapshot.selectedIDs(
            from: rows,
            filterStatus: .unmastered
        )
        assert(paperSelectionIDs == [rows[0].id], "paper selection should select unmastered cards by status")
        assert(
            PaperSelectionSnapshot.initiallySelectedIDs(from: rows) == [rows[0].id],
            "paper selection should initially skip mastered cards"
        )

        let allPaperSelection = PaperSelectionSnapshot(
            availableCards: rows,
            filterStatus: .all,
            selectedIDs: Set(rows.map(\.id))
        )
        assert(allPaperSelection.displayCards.count == 2, "all filter should display every card")
        assert(allPaperSelection.selectedOrderedIDs == rows.map(\.id), "selected IDs should preserve available card order")
        assert(allPaperSelection.allSelected, "snapshot should report all selected when every visible card is selected")

        let partialPaperSelection = PaperSelectionSnapshot(
            availableCards: rows,
            filterStatus: .all,
            selectedIDs: [rows[0].id]
        )
        assert(!partialPaperSelection.allSelected, "snapshot should detect partial selections")
        assert(partialPaperSelection.selectedOrderedIDs == [rows[0].id], "partial selected IDs should keep selected visible order")

        let modelCard = MistakeCard(
            imageFileName: "model.png",
            originalWidth: 100,
            originalHeight: 50,
            tagsText: "函数,一次函数,图像"
        )
        assert(modelCard.tagPreviewText == "函数 · 一次函数", "model tag preview should reuse shared display helper")

        let searchable = makeRow(
            subject: Subject.english.rawValue,
            tagsText: "阅读理解",
            note: "注意定位关键词",
            recognizedText: "Read the passage",
            questionType: "选择题",
            correctAnswer: "A",
            sourceDocumentTitle: "英语周测"
        )
        assert(searchable.matchesSearch("定位"), "search should match notes")
        assert(searchable.matchesSearch("passage"), "search should match recognized text")
        assert(searchable.matchesSearch("选择题"), "search should match resolved question type")
        assert(searchable.matchesSearch("英语周测"), "search should match source document")
        assert(!searchable.matchesSearch("不存在"), "search should reject unrelated text")
        assert(
            searchable.matchesFilters(
                selectedStatus: MasteryStatus.unmastered.rawValue,
                selectedQuestionType: "选择题",
                selectedTag: "阅读理解",
                selectedSource: "英语周测"
            ),
            "filter helper should accept matching status, type, tag and source"
        )
        assert(
            !searchable.matchesFilters(
                selectedStatus: MasteryStatus.mastered.rawValue,
                selectedQuestionType: "选择题",
                selectedTag: "阅读理解",
                selectedSource: "英语周测"
            ),
            "filter helper should reject nonmatching status"
        )

        let cardA = UUID()
        let cardB = UUID()
        let groupA = UUID()
        let groupB = UUID()
        let practiceCounts = MistakePracticeRoundCounter.countByCardID([
            MistakePracticeRoundCountInput(cardID: cardA, practiceGroupID: groupA, round: 1),
            MistakePracticeRoundCountInput(cardID: cardA, practiceGroupID: groupA, round: 1),
            MistakePracticeRoundCountInput(cardID: cardA, practiceGroupID: groupA, round: 2),
            MistakePracticeRoundCountInput(cardID: cardA, practiceGroupID: groupB, round: 1),
            MistakePracticeRoundCountInput(cardID: cardB, practiceGroupID: groupA, round: 1)
        ])
        assert(practiceCounts[cardA] == 3, "practice count should deduplicate only identical group and round pairs")
        assert(practiceCounts[cardB] == 1, "practice count should group by card")

        let relatedSnapshot = RelatedMistakeSnapshot(
            card: rows[0],
            sharedTags: ["函数", "一次函数", "图像", "坐标"]
        )
        assert(relatedSnapshot.sharedTagPreviewText == "函数 · 一次函数 · 图像", "related mistakes should preview at most three shared tags")
        assert(relatedSnapshot.sharedTagsAccessibilityText == "函数、一次函数、图像、坐标", "related mistakes should expose all tags for accessibility")

        let currentID = UUID()
        let olderTwoTagMatch = makeRow(
            tagsText: "函数,一次函数",
            createdAt: Date(timeIntervalSince1970: 10)
        )
        let newerTwoTagMatch = makeRow(
            tagsText: "函数,一次函数,函数",
            createdAt: Date(timeIntervalSince1970: 30)
        )
        let oneTagMatch = makeRow(
            tagsText: "函数",
            createdAt: Date(timeIntervalSince1970: 40)
        )
        let unrelated = makeRow(
            tagsText: "力学",
            createdAt: Date(timeIntervalSince1970: 50)
        )
        let current = makeRow(
            id: currentID,
            tagsText: "函数,一次函数",
            createdAt: Date(timeIntervalSince1970: 60)
        )

        let relatedMatches = RelatedMistakeMatcher.topMatches(
            candidates: [oneTagMatch, unrelated, olderTwoTagMatch, current, newerTwoTagMatch],
            currentCardID: currentID,
            tags: ["函数", "一次函数"],
            limit: 3
        )
        assert(
            relatedMatches.map(\.card.id) == [
                newerTwoTagMatch.id,
                olderTwoTagMatch.id,
                oneTagMatch.id
            ],
            "related matcher should rank by shared tags, then newest, and skip current/unrelated cards"
        )
        assert(
            relatedMatches[0].sharedTags == ["一次函数", "函数"],
            "related matcher should deduplicate repeated card tags before ranking"
        )

        print("MistakeListSnapshotTests: 41 passed")
    }
}
