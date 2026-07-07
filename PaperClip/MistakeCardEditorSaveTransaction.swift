import Foundation
import SwiftData

enum MistakeCardEditorSaveTransaction {
    static func save(
        card: MistakeCard,
        nextPrintHeight: Double,
        in modelContext: ModelContext
    ) throws {
        card.printHeightMM = nextPrintHeight
        card.updatedAt = .now
        try modelContext.saveOrRollbackIfNeeded()
    }
}
