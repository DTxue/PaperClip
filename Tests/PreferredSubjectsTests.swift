import Foundation

@main
struct PreferredSubjectsTests {
    static func main() {
        testParseTrimsWhitespaceAndDropsEmptyItems()
        testParsePreservesUserOrder()
        testParseSetTrimsWhitespaceAndDeduplicates()
        testSerializeUsesSubjectOrder()
        testDefaultSubjectUsesFirstPreferredSubject()
        testDefaultSubjectFallsBackToMath()
        print("PreferredSubjectsTests: 6 passed")
    }

    private static func testParseTrimsWhitespaceAndDropsEmptyItems() {
        let result = PreferredSubjects.parse(" 数学, ,英语,\n物理 ")
        expect(result == ["数学", "英语", "物理"])
    }

    private static func testParsePreservesUserOrder() {
        let result = PreferredSubjects.parse("英语,数学,语文")
        expect(result == ["英语", "数学", "语文"])
    }

    private static func testParseSetTrimsWhitespaceAndDeduplicates() {
        let result = PreferredSubjects.parseSet(" 数学,英语,数学, ")
        expect(result == ["数学", "英语"])
    }

    private static func testSerializeUsesSubjectOrder() {
        let result = PreferredSubjects.serialize([
            Subject.english.rawValue,
            Subject.math.rawValue,
            Subject.chinese.rawValue
        ])
        expect(result == "语文,数学,英语")
    }

    private static func testDefaultSubjectUsesFirstPreferredSubject() {
        expect(PreferredSubjects.defaultSubject("英语,数学,语文") == "英语")
    }

    private static func testDefaultSubjectFallsBackToMath() {
        expect(PreferredSubjects.defaultSubject(" , , ") == "数学")
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
