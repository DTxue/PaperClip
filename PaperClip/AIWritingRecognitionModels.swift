import Foundation

struct AIWritingRecognitionResult: Decodable, Sendable {
    let recognizedText: String
    let possibleIssues: [String]

    private enum CodingKeys: String, CodingKey {
        case recognizedText, possibleIssues
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        recognizedText = container.decodeString(.recognizedText)
        possibleIssues = container.decodeStringArray(.possibleIssues)
    }
}
