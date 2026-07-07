import Foundation

struct WritingPromptGenerationDraft: Equatable {
    var language: WritingLanguage
    var studentGrade: String
    var requirementInput: String

    var trimmedRequirement: String {
        requirementInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canGenerate: Bool {
        !trimmedRequirement.isEmpty
    }
}
