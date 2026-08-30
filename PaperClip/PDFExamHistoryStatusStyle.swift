import SwiftUI

enum ExamAttemptHistoryStatusStyle: Hashable {
    case graded
    case submitted
    case inProgress

    init(status: String) {
        switch ExamAttemptStatus(rawValue: status) {
        case .graded:
            self = .graded
        case .submitted:
            self = .submitted
        default:
            self = .inProgress
        }
    }

    var title: String {
        switch self {
        case .graded:
            return "已批阅"
        case .submitted:
            return "已交卷"
        case .inProgress:
            return "进行中"
        }
    }

    var iconName: String {
        switch self {
        case .graded:
            return "checkmark.seal.fill"
        case .submitted:
            return "tray.full.fill"
        case .inProgress:
            return "pencil.and.scribble"
        }
    }

    var color: Color {
        switch self {
        case .graded:
            return .green
        case .submitted:
            return .orange
        case .inProgress:
            return .accentColor
        }
    }

    var allowsManualDeletion: Bool {
        self == .inProgress
    }
}
