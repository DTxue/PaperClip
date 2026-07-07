enum MasteryStatus: String, CaseIterable, Identifiable {
    case unmastered = "未掌握"
    case review = "待复习"
    case mastered = "已掌握"
    var id: String { rawValue }

    /// 升一级：未掌握 → 待复习 → 已掌握（已掌握不变）。
    static func nextLevel(after status: String) -> MasteryStatus {
        switch status {
        case unmastered.rawValue: return .review
        case review.rawValue: return .mastered
        default: return .mastered
        }
    }
}

enum ErrorReason: String, CaseIterable, Identifiable {
    case concept = "概念不清"
    case calculation = "计算错误"
    case reading = "审题错误"
    case careless = "粗心"
    case incomplete = "步骤不完整"
    case formula = "公式记错"
    case method = "方法不会"
    case other = "其他"
    var id: String { rawValue }
}

enum RecognitionStatus: String {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
}

enum ExamAttemptStatus: String {
    case inProgress = "in_progress"
    case submitted = "submitted"
    case graded = "graded"

    var canSubmit: Bool {
        self == .inProgress
    }

    var isTerminal: Bool {
        self == .graded
    }

    static func canSubmit(_ rawValue: String) -> Bool {
        ExamAttemptStatus(rawValue: rawValue)?.canSubmit ?? false
    }
}
