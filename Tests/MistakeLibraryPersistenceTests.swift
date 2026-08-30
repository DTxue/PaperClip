import Foundation
import SwiftData
import PencilKit

@MainActor
@main
enum MistakeLibraryPersistenceTests {
    static func main() throws {
        let schema = Schema([
            MistakeLibraryItem.self,
            MistakeAttachment.self,
            MistakeReviewAttempt.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        let attachmentDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MistakeLibraryPersistenceTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: attachmentDirectory) }
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let item = MistakeLibraryItem(
            questionText: "1 + 1 = ?",
            correctAnswer: "2",
            status: .learning,
            nextReviewAt: now
        )
        context.insert(item)
        try context.save()

        try MistakeLibraryPersistence.recordReview(
            for: item,
            outcome: .correct,
            drawing: PKDrawing(),
            note: "第一次重做",
            in: context,
            now: now,
            calendar: calendar
        )
        expect(item.correctStreak == 1, "review advances the correct streak")
        expect(item.reviewCount == 1, "review increments the count")
        expect(item.status == .learning, "first correct review remains in learning")
        expect(
            item.nextReviewAt == calendar.date(byAdding: .day, value: 3, to: now),
            "review schedules the next date"
        )
        var attempts = try context.fetch(FetchDescriptor<MistakeReviewAttempt>())
        expect(attempts.count == 1, "review persists one attempt")
        expect(attempts[0].note == "第一次重做", "review persists its note")

        try MistakeLibraryPersistence.moveToTrash(item, in: context, now: now)
        expect(item.deletedAt == now, "trash is a soft delete")
        try MistakeLibraryPersistence.restore(item, in: context, now: now)
        expect(item.deletedAt == nil, "restore clears the soft delete")

        try MistakeLibraryPersistence.setFavorite(true, for: item, in: context, now: now)
        expect(item.isFavorite, "favorite changes are persisted through the domain store")
        let statusBeforeArchive = item.status
        try MistakeLibraryPersistence.toggleArchive(item, in: context, now: now)
        expect(item.status == .archived, "archive changes are persisted through the domain store")
        try MistakeLibraryPersistence.toggleArchive(item, in: context, now: now)
        expect(item.status == statusBeforeArchive, "unarchive restores the previous learning status")

        let savedItem = try MistakeLibraryPersistence.saveItem(
            existing: item,
            input: MistakeEditorInput(
                questionText: " 1 + 1 = ? ",
                errorReason: " 粗心 ",
                subject: Subject.math.rawValue,
                grade: Grade.grade8.rawValue,
                semester: Semester.second.rawValue,
                source: " 练习册 ",
                tagsText: "计算，基础"
            ),
            pendingAttachments: [
                MistakePendingAttachment(
                    data: Data([0x01, 0x02]),
                    pathExtension: "png",
                    originalFileName: "question.png"
                )
            ],
            in: context,
            attachmentDirectory: attachmentDirectory,
            now: now
        )
        expect(savedItem.tags == ["计算", "基础"], "editor persistence normalizes tags")
        expect(savedItem.grade == Grade.grade8.rawValue, "editor persistence saves grade")
        expect(savedItem.semester == Semester.second.rawValue, "editor persistence saves semester")
        let savedAttachments = try context.fetch(FetchDescriptor<MistakeAttachment>())
        expect(savedAttachments.count == 1, "editor persistence stores attachments")
        let attachment = savedAttachments[0]
        expect(
            FileManager.default.fileExists(
                atPath: attachmentDirectory.appendingPathComponent(attachment.fileName).path
            ),
            "editor persistence writes attachment bytes"
        )
        attempts = try context.fetch(FetchDescriptor<MistakeReviewAttempt>())
        try MistakeLibraryPersistence.permanentlyDelete(
            item,
            attachments: [attachment],
            attempts: attempts,
            in: context,
            attachmentDirectory: attachmentDirectory
        )
        let remainingItems = try context.fetch(FetchDescriptor<MistakeLibraryItem>())
        let remainingAttachments = try context.fetch(FetchDescriptor<MistakeAttachment>())
        let remainingAttempts = try context.fetch(FetchDescriptor<MistakeReviewAttempt>())
        expect(remainingItems.isEmpty, "permanent deletion removes the item")
        expect(remainingAttachments.isEmpty, "permanent deletion removes attachments")
        expect(remainingAttempts.isEmpty, "permanent deletion removes attempts")
        expect(
            !FileManager.default.fileExists(
                atPath: attachmentDirectory.appendingPathComponent(attachment.fileName).path
            ),
            "permanent deletion commits attachment removal"
        )

        print("MistakeLibraryPersistenceTests: 21 passed")
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError(message, file: file, line: line)
        }
    }
}
