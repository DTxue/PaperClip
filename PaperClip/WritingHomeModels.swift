import Foundation
import SwiftData

struct WritingPromptRowData: Identifiable, Equatable {
    let id: UUID
    let language: WritingLanguage
    let studentGrade: String
    let requirementInput: String
    let title: String
    let requirement: String

    init(prompt: WritingPrompt) {
        self.id = prompt.id
        self.language = prompt.language
        self.studentGrade = prompt.studentGrade
        self.requirementInput = prompt.requirementInput
        self.title = prompt.generatedTitle
        self.requirement = prompt.generatedRequirement
    }

    func matchesSearch(_ normalizedSearch: String) -> Bool {
        normalizedSearch.isEmpty
            || title.localizedCaseInsensitiveContains(normalizedSearch)
            || requirement.localizedCaseInsensitiveContains(normalizedSearch)
            || requirementInput.localizedCaseInsensitiveContains(normalizedSearch)
    }

    static var propertiesToFetch: [PartialKeyPath<WritingPrompt>] {
        [
            \.id,
            \.languageRaw,
            \.studentGrade,
            \.requirementInput,
            \.generatedTitle,
            \.generatedRequirement
        ]
    }
}

struct WritingDraftRowData: Identifiable, Equatable {
    let id: UUID
    let promptID: UUID
    let reviewStatus: WritingReviewStatus
    let updatedAt: Date

    init(draft: WritingDraft) {
        self.id = draft.id
        self.promptID = draft.promptID
        self.reviewStatus = draft.reviewStatus
        self.updatedAt = draft.updatedAt
    }

    static var propertiesToFetch: [PartialKeyPath<WritingDraft>] {
        [\.id, \.promptID, \.reviewStatusRaw, \.updatedAt]
    }
}

struct WritingReviewRowData: Identifiable, Equatable {
    let id: UUID
    let promptID: UUID
    let scoreText: String
    let summaryText: String
    let createdAt: Date

    init(review: WritingReview) {
        self.id = review.id
        self.promptID = review.promptID
        self.scoreText = review.scoreText
        self.summaryText = review.overallJudgement.isEmpty ? review.teacherComment : review.overallJudgement
        self.createdAt = review.createdAt
    }

    static var propertiesToFetch: [PartialKeyPath<WritingReview>] {
        [\.id, \.promptID, \.scoreText, \.overallJudgement, \.teacherComment, \.createdAt]
    }
}
