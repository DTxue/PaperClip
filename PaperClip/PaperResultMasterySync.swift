import Foundation
import SwiftData

enum PaperResultMasterySync {
    static func sync(cards: [MistakeCard], marks: [UUID: String], in modelContext: ModelContext) throws {
        for card in cards {
            switch marks[card.id] {
            case PracticeMark.gotIt.rawValue:
                card.status = MasteryStatus.nextLevel(after: card.status).rawValue
                card.updatedAt = .now
            case PracticeMark.notYet.rawValue:
                card.status = MasteryStatus.unmastered.rawValue
                card.updatedAt = .now
            default:
                break
            }
        }

        try modelContext.saveOrRollbackIfNeeded()
    }
}
