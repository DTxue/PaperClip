import Foundation

func assert(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fatalError(message)
    }
}

func assertEqual(_ lhs: Double, _ rhs: Double, accuracy: Double = 0.0001, _ message: String) {
    assert(abs(lhs - rhs) <= accuracy, message)
}

@main
struct MasteryStatusSummaryTests {
    static func main() {
        let empty = MasteryStatusSummary(mastered: 0, review: 0, unmastered: 0, total: 0)
        assert(!empty.hasItems, "empty summary should not have items")
        assertEqual(empty.masteredRatio, 0, "empty mastered ratio")
        assertEqual(empty.reviewRatio, 0, "empty review ratio")
        assertEqual(empty.unmasteredRatio, 0, "empty unmastered ratio")
        assert(empty.masteredPercent == 0, "empty mastered percent")

        let summary = MasteryStatusSummary(mastered: 3, review: 2, unmastered: 5, total: 10)
        assert(summary.hasItems, "non-empty summary should have items")
        assertEqual(summary.masteredRatio, 0.3, "mastered ratio")
        assertEqual(summary.reviewRatio, 0.2, "review ratio")
        assertEqual(summary.unmasteredRatio, 0.5, "unmastered ratio")
        assert(summary.masteredPercent == 30, "mastered percent")
        assert(summary.segments.map(\.status) == [.unmastered, .review, .mastered], "segment order")
        assert(summary.segments.map(\.count) == [5, 2, 3], "segment counts")
        assertEqual(summary.segments[0].ratio, 0.5, "unmastered segment ratio")
        assert(summary.segments[0].label == "未掌握", "unmastered segment label")
        assert(summary.segments[0].systemImage == "xmark.circle.fill", "unmastered segment icon")
        assert(summary.segments[1].systemImage == "clock.fill", "review segment icon")
        assert(summary.segments[2].systemImage == "checkmark.circle.fill", "mastered segment icon")

        var counter = MasteryStatusCounter()
        counter.add(MasteryStatus.mastered.rawValue)
        counter.add(MasteryStatus.review.rawValue)
        counter.add("未知状态")
        assert(counter.summary.mastered == 1, "counter should count mastered")
        assert(counter.summary.review == 1, "counter should count review")
        assert(counter.summary.unmastered == 1, "counter should treat unknown statuses as unmastered")
        assert(counter.summary.total == 3, "counter total")

        print("MasteryStatusSummaryTests: 13 passed")
    }
}
