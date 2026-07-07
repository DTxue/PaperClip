import Foundation
import SwiftData

extension ModelContext {
    func deleteWritingPromptCascade(promptID: UUID) throws {
        try deleteFetched(FetchDescriptor<WritingDraft>(
            predicate: #Predicate<WritingDraft> { draft in draft.promptID == promptID }
        ), fetching: WritingDraft.deletionPropertiesToFetch)

        try deleteFetched(FetchDescriptor<WritingReview>(
            predicate: #Predicate<WritingReview> { review in review.promptID == promptID }
        ), fetching: WritingReview.deletionPropertiesToFetch)

        if let prompt = try fetchWritingPrompt(id: promptID) {
            delete(prompt)
        }
    }
}
