import Foundation
import SwiftData

@main
struct MistakePersistenceTests {
    @MainActor
    static func main() throws {
        let schema = Schema([
            MistakeCard.self,
            MistakePracticeLayer.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        expect(MistakeCard.unfinishedRecognitionPropertiesToFetch.count == 3)
        expect(MistakePracticeLayer.roundCountPropertiesToFetch.count == 3)
        expect(MistakePracticeLayer.deletionPropertiesToFetch.count == 1)

        let cardA = MistakeCard(
            imageFileName: "a.jpg",
            originalWidth: 100,
            originalHeight: 50,
            recognitionStatus: RecognitionStatus.pending.rawValue
        )
        let cardB = MistakeCard(
            imageFileName: "b.jpg",
            originalWidth: 100,
            originalHeight: 50,
            recognitionStatus: RecognitionStatus.completed.rawValue
        )
        context.insert(cardA)
        context.insert(cardB)

        let groupA = UUID()
        context.insert(MistakePracticeLayer(cardID: cardA.id, practiceGroupID: groupA, round: 1))
        context.insert(MistakePracticeLayer(cardID: cardA.id, practiceGroupID: groupA, round: 1))
        context.insert(MistakePracticeLayer(cardID: cardA.id, practiceGroupID: groupA, round: 2))
        context.insert(MistakePracticeLayer(cardID: cardB.id, practiceGroupID: UUID(), round: 1))
        try context.save()

        let unfinished = try context.fetchUnfinishedRecognitionMistakeCards()
        expect(unfinished.map(\.id) == [cardA.id])

        let counts = try context.fetchMistakePracticeRoundCounts(cardIDs: [cardA.id, cardB.id])
        expect(counts[cardA.id] == 2)
        expect(counts[cardB.id] == 1)

        let deleted = try context.deleteMistakePracticeLayers(cardID: cardA.id)
        expect(deleted == 3)
        let remainingCounts = try context.fetchMistakePracticeRoundCounts(cardIDs: [cardA.id, cardB.id])
        expect(remainingCounts[cardA.id] == nil)
        expect(remainingCounts[cardB.id] == 1)

        cardA.status = MasteryStatus.review.rawValue
        cardB.status = MasteryStatus.mastered.rawValue
        let unknownCard = MistakeCard(imageFileName: "c.jpg", originalWidth: 100, originalHeight: 50)
        context.insert(unknownCard)
        try PaperResultMasterySync.sync(
            cards: [cardA, cardB, unknownCard],
            marks: [
                cardA.id: PracticeMark.gotIt.rawValue,
                cardB.id: PracticeMark.notYet.rawValue
            ],
            in: context
        )

        expect(cardA.status == MasteryStatus.mastered.rawValue)
        expect(cardB.status == MasteryStatus.unmastered.rawValue)
        expect(unknownCard.status == MasteryStatus.unmastered.rawValue)

        print("MistakePersistenceTests: 13 passed")
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError("Expectation failed", file: file, line: line)
        }
    }
}
