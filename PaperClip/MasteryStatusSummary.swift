import Foundation

struct MasteryStatusSummary {
    let mastered: Int
    let review: Int
    let unmastered: Int
    let total: Int

    static let empty = MasteryStatusSummary(mastered: 0, review: 0, unmastered: 0, total: 0)

    init(mastered: Int, review: Int, unmastered: Int, total: Int) {
        self.mastered = mastered
        self.review = review
        self.unmastered = unmastered
        self.total = total
    }

    init(cards: [MistakeCard]) {
        var counter = MasteryStatusCounter()
        for card in cards {
            counter.add(card.status)
        }
        self = counter.summary
    }

    var masteredRatio: Double {
        total == 0 ? 0 : Double(mastered) / Double(total)
    }

    var reviewRatio: Double {
        total == 0 ? 0 : Double(review) / Double(total)
    }

    var unmasteredRatio: Double {
        total == 0 ? 0 : Double(unmastered) / Double(total)
    }

    var hasItems: Bool {
        total > 0
    }

    var masteredPercent: Int {
        Int(masteredRatio * 100)
    }

    var segments: [MasteryStatusSegment] {
        [
            MasteryStatusSegment(
                status: .unmastered,
                count: unmastered,
                ratio: unmasteredRatio
            ),
            MasteryStatusSegment(
                status: .review,
                count: review,
                ratio: reviewRatio
            ),
            MasteryStatusSegment(
                status: .mastered,
                count: mastered,
                ratio: masteredRatio
            )
        ]
    }
}

struct MasteryStatusCounter {
    private(set) var mastered = 0
    private(set) var review = 0
    private(set) var unmastered = 0

    var total: Int {
        mastered + review + unmastered
    }

    var summary: MasteryStatusSummary {
        MasteryStatusSummary(
            mastered: mastered,
            review: review,
            unmastered: unmastered,
            total: total
        )
    }

    mutating func add(_ status: String) {
        switch status {
        case MasteryStatus.mastered.rawValue:
            mastered += 1
        case MasteryStatus.review.rawValue:
            review += 1
        default:
            unmastered += 1
        }
    }
}
