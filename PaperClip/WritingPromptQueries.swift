import Foundation
import SwiftData

extension ModelContext {
    func fetchWritingPrompts(
        language: WritingLanguage,
        propertiesToFetch: [PartialKeyPath<WritingPrompt>] = []
    ) throws -> [WritingPrompt] {
        let languageRaw = language.rawValue
        let descriptor = FetchDescriptor<WritingPrompt>(
            predicate: #Predicate<WritingPrompt> { prompt in
                prompt.languageRaw == languageRaw
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try fetchConfigured(descriptor, propertiesToFetch: propertiesToFetch)
    }

    func fetchWritingPrompt(id: UUID) throws -> WritingPrompt? {
        let descriptor = FetchDescriptor<WritingPrompt>(
            predicate: #Predicate<WritingPrompt> { prompt in
                prompt.id == id
            }
        )
        return try fetchFirst(descriptor)
    }
}
