import Foundation

struct MasteryStatusSegment: Equatable {
    let status: MasteryStatus
    let count: Int
    let ratio: Double

    var label: String {
        status.rawValue
    }

    var systemImage: String {
        switch status {
        case .mastered: "checkmark.circle.fill"
        case .review: "clock.fill"
        case .unmastered: "xmark.circle.fill"
        }
    }
}
