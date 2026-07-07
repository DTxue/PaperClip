enum MistakeRecognitionStatusSupport {
    static func isUnfinished(_ rawValue: String) -> Bool {
        switch RecognitionStatus(rawValue: rawValue) {
        case .pending, .processing, .failed:
            return true
        case .completed, nil:
            return false
        }
    }

    static func recoveryStatus(from rawValue: String) -> String {
        isUnfinished(rawValue) ? RecognitionStatus.pending.rawValue : rawValue
    }
}
