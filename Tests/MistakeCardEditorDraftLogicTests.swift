import Foundation

@main
struct MistakeCardEditorDraftLogicTests {
    static func main() {
        testPrintHeightUsesMinimumAspectRatio()
        testSubjectsFallbackToAllSubjects()
        testSubjectsFollowPreferredOrderAndIncludeCurrentSubject()
        testAppendingTagsNormalizesAndDeduplicates()
        testRemovingTagSerializesRemainingTags()
        print("MistakeCardEditorDraftLogicTests: 9 passed")
    }

    private static func testPrintHeightUsesMinimumAspectRatio() {
        expect(MistakeCardEditorDraftLogic.printHeight(printWidthMM: 100, aspectRatio: 2) == 50)
        expect(MistakeCardEditorDraftLogic.printHeight(printWidthMM: 100, aspectRatio: 0) == 10_000)
    }

    private static func testSubjectsFallbackToAllSubjects() {
        expect(MistakeCardEditorDraftLogic.subjectsForPicker(preferredSubjectsRaw: "", currentSubject: "数学") == Subject.allCases)
    }

    private static func testSubjectsFollowPreferredOrderAndIncludeCurrentSubject() {
        let subjects = MistakeCardEditorDraftLogic.subjectsForPicker(
            preferredSubjectsRaw: "英语,数学",
            currentSubject: "物理"
        )
        expect(subjects.map(\.rawValue) == ["数学", "英语", "物理"])

        let alreadyIncluded = MistakeCardEditorDraftLogic.subjectsForPicker(
            preferredSubjectsRaw: "英语,数学",
            currentSubject: "数学"
        )
        expect(alreadyIncluded.map(\.rawValue) == ["数学", "英语"])
    }

    private static func testAppendingTagsNormalizesAndDeduplicates() {
        let result = MistakeCardEditorDraftLogic.appendingTags("函数，图像\n函数", to: "函数,一次函数")
        expect(result == "函数,一次函数,图像")
    }

    private static func testRemovingTagSerializesRemainingTags() {
        expect(MistakeCardEditorDraftLogic.removingTag("函数", from: "函数,一次函数,图像") == "一次函数,图像")
        expect(MistakeCardEditorDraftLogic.removingTag("不存在", from: "函数,图像") == "函数,图像")
        expect(MistakeCardEditorDraftLogic.removingTag("函数", from: "函数") == "")
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
