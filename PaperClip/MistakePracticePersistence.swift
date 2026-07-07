import Foundation
import SwiftData

extension ModelContext {
    func fetchMistakePracticeLayers(
        cardIDs: [UUID],
        propertiesToFetch: [PartialKeyPath<MistakePracticeLayer>] = []
    ) throws -> [MistakePracticeLayer] {
        guard !cardIDs.isEmpty else { return [] }
        var descriptor = FetchDescriptor<MistakePracticeLayer>(
            predicate: #Predicate<MistakePracticeLayer> { layer in
                cardIDs.contains(layer.cardID)
            }
        )
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetch(descriptor)
    }

    func fetchMistakePracticeRoundCounts(cardIDs: [UUID]) throws -> [UUID: Int] {
        let layers = try fetchMistakePracticeLayers(
            cardIDs: cardIDs,
            propertiesToFetch: MistakePracticeLayer.roundCountPropertiesToFetch
        )
        return MistakePracticeRoundCounter.countByCardID(layers) { layer in
            (layer.cardID, layer.practiceGroupID, layer.round)
        }
    }

    func fetchMarkedMistakePracticeLayers(
        since startDate: Date,
        propertiesToFetch: [PartialKeyPath<MistakePracticeLayer>] = []
    ) throws -> [MistakePracticeLayer] {
        let gotIt = PracticeMark.gotIt.rawValue
        let notYet = PracticeMark.notYet.rawValue
        var descriptor = FetchDescriptor<MistakePracticeLayer>(
            predicate: #Predicate<MistakePracticeLayer> { layer in
                layer.createdAt >= startDate && (layer.mark == gotIt || layer.mark == notYet)
            }
        )
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetch(descriptor)
    }

    @discardableResult
    func deleteMistakePracticeLayers(cardID: UUID) throws -> Int {
        var descriptor = FetchDescriptor<MistakePracticeLayer>(
            predicate: #Predicate<MistakePracticeLayer> { layer in
                layer.cardID == cardID
            }
        )
        descriptor.propertiesToFetch = MistakePracticeLayer.deletionPropertiesToFetch
        return try deleteFetched(descriptor)
    }
}
