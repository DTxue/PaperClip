import Foundation
import SwiftData

@Model
final class WritingPrompt {
    static var deletionPropertiesToFetch: [PartialKeyPath<WritingPrompt>] {
        [\.id]
    }

    @Attribute(.unique) var id: UUID
    var languageRaw: String
    var studentGrade: String
    var requirementInput: String
    var generatedTitle: String
    var generatedRequirement: String
    var constraintsText: String
    var rubricText: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        language: WritingLanguage,
        studentGrade: String,
        requirementInput: String,
        generatedTitle: String,
        generatedRequirement: String,
        constraints: [String] = [],
        rubric: [String] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.languageRaw = language.rawValue
        self.studentGrade = studentGrade
        self.requirementInput = requirementInput
        self.generatedTitle = generatedTitle
        self.generatedRequirement = generatedRequirement
        self.constraintsText = constraints.joined(separator: "\n")
        self.rubricText = rubric.joined(separator: "\n")
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var language: WritingLanguage {
        get { WritingLanguage(rawValue: languageRaw) ?? .chinese }
        set { languageRaw = newValue.rawValue }
    }

    var constraints: [String] {
        constraintsText
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    var rubric: [String] {
        rubricText
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.isEmpty }
    }
}
