import CoreGraphics
import Foundation

enum VocabularyReviewRating: Int, CaseIterable, Identifiable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .again: "忘记"
        case .hard: "困难"
        case .good: "记得"
        case .easy: "简单"
        }
    }

    var systemImage: String {
        switch self {
        case .again: "arrow.counterclockwise"
        case .hard: "brain"
        case .good: "checkmark"
        case .easy: "sparkles"
        }
    }

    var isPassingRecall: Bool {
        self != .again
    }

    var swipeDirection: CGFloat {
        switch self {
        case .again, .hard: -1
        case .good, .easy: 1
        }
    }

    var usesProminentButton: Bool {
        self == .good
    }
}
