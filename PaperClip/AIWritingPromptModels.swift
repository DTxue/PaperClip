import Foundation

struct AIWritingPromptResult: Decodable, Sendable {
    let title: String
    let requirement: String
    let constraints: [String]
    let rubric: [String]

    private enum CodingKeys: String, CodingKey {
        case title, requirement, constraints, rubric
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = container.decodeString(.title, fallback: "写作练习")
        requirement = container.decodeString(.requirement)
        constraints = container.decodeStringArray(.constraints)
        rubric = container.decodeStringArray(.rubric)
    }
}
