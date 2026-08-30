enum ExamAttemptStatus: String {
    case inProgress = "in_progress"
    case submitted = "submitted"
    case graded = "graded"

    var canSubmit: Bool {
        self == .inProgress
    }

    var canRequestGrading: Bool {
        self == .inProgress || self == .submitted
    }

    var isTerminal: Bool {
        self == .graded
    }

    static func canSubmit(_ rawValue: String) -> Bool {
        ExamAttemptStatus(rawValue: rawValue)?.canSubmit ?? false
    }

    static func canRequestGrading(_ rawValue: String) -> Bool {
        ExamAttemptStatus(rawValue: rawValue)?.canRequestGrading ?? false
    }
}
