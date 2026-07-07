import Foundation
import SwiftData

extension ModelContext {
    func fetchMistakeCard(id: UUID) throws -> MistakeCard? {
        let descriptor = FetchDescriptor<MistakeCard>(
            predicate: #Predicate<MistakeCard> { card in
                card.id == id
            }
        )
        return try fetchFirst(descriptor)
    }

    func fetchUnfinishedRecognitionMistakeCards() throws -> [MistakeCard] {
        let pending = RecognitionStatus.pending.rawValue
        let processing = RecognitionStatus.processing.rawValue
        let failed = RecognitionStatus.failed.rawValue
        var descriptor = FetchDescriptor<MistakeCard>(
            predicate: #Predicate<MistakeCard> { card in
                card.recognitionStatus == pending
                    || card.recognitionStatus == processing
                    || card.recognitionStatus == failed
            }
        )
        descriptor.propertiesToFetch = MistakeCard.unfinishedRecognitionPropertiesToFetch
        return try fetch(descriptor)
    }

    func fetchMistakeCards(ids orderedIDs: [UUID]) throws -> [MistakeCard] {
        guard !orderedIDs.isEmpty else { return [] }
        let descriptor = FetchDescriptor<MistakeCard>(
            predicate: #Predicate<MistakeCard> { card in
                orderedIDs.contains(card.id)
            }
        )
        let fetched = try fetch(descriptor)
        var cardByID: [UUID: MistakeCard] = [:]
        cardByID.reserveCapacity(fetched.count)
        for card in fetched {
            cardByID[card.id] = card
        }
        return orderedIDs.compactMap { cardByID[$0] }
    }

    func fetchMistakeCards(
        subject: String?,
        propertiesToFetch: [PartialKeyPath<MistakeCard>] = []
    ) throws -> [MistakeCard] {
        var descriptor: FetchDescriptor<MistakeCard>
        if let subject {
            descriptor = FetchDescriptor<MistakeCard>(
                predicate: #Predicate<MistakeCard> { card in
                    card.subject == subject
                },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<MistakeCard>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        }
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetch(descriptor)
    }

    func fetchRelatedMistakeCards(
        subject: String,
        excluding excludedID: UUID,
        propertiesToFetch: [PartialKeyPath<MistakeCard>] = []
    ) throws -> [MistakeCard] {
        var descriptor = FetchDescriptor<MistakeCard>(
            predicate: #Predicate<MistakeCard> { card in
                card.subject == subject && card.id != excludedID
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetch(descriptor)
    }

    func deleteMistakeCardCascade(cardID: UUID) throws -> URL? {
        try deleteMistakePracticeLayers(cardID: cardID)
        guard let card = try fetchMistakeCard(id: cardID) else {
            return nil
        }
        let imageURL = card.imageURL
        delete(card)
        return imageURL
    }
}
