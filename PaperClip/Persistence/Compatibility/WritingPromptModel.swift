import Foundation
import SwiftData

/// Historical V1–V4 migration model. Writing is not part of the current schema.
extension PaperClipSchemaV1 {
@Model
final class WritingPrompt {
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
        languageRaw: String,
        studentGrade: String,
        requirementInput: String,
        generatedTitle: String,
        generatedRequirement: String,
        constraintsText: String = "",
        rubricText: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.languageRaw = languageRaw
        self.studentGrade = studentGrade
        self.requirementInput = requirementInput
        self.generatedTitle = generatedTitle
        self.generatedRequirement = generatedRequirement
        self.constraintsText = constraintsText
        self.rubricText = rubricText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
}
