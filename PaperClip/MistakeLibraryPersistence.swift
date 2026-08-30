import Foundation
import PencilKit
import SwiftData

struct MistakePendingAttachment {
    let data: Data
    let pathExtension: String?
    let originalFileName: String
}

struct MistakeEditorInput {
    let questionText: String
    let errorReason: String
    let subject: String
    let grade: String
    let semester: String
    let source: String
    let tagsText: String
}

@MainActor
enum MistakeLibraryPersistence {
    @discardableResult
    static func saveItem(
        existing item: MistakeLibraryItem?,
        input: MistakeEditorInput,
        pendingAttachments: [MistakePendingAttachment],
        in context: ModelContext,
        attachmentDirectory: URL = AppStorageDirectory.mistakeAttachments,
        now: Date = .now
    ) throws -> MistakeLibraryItem {
        let target = item ?? MistakeLibraryItem(createdAt: now, updatedAt: now)
        if item == nil {
            context.insert(target)
        }
        target.questionText = trimmed(input.questionText)
        target.errorReason = trimmed(input.errorReason)
        target.subject = input.subject
        target.grade = input.grade
        target.semester = input.semester
        target.source = trimmed(input.source)
        target.tagsText = normalizedTags(input.tagsText)
        target.updatedAt = now

        if target.status == .inbox && !target.questionText.isEmpty {
            target.status = .learning
            target.nextReviewAt = target.nextReviewAt
                ?? MistakeReviewEngine.initialReviewDate(from: now)
        }

        let existingAttachments = try context.fetch(FetchDescriptor<MistakeAttachment>())
            .filter { $0.itemID == target.id }
        let startingIndex = (existingAttachments.map(\.sortIndex).max() ?? -1) + 1
        var savedFileNames: [String] = []
        do {
            for (offset, attachment) in pendingAttachments.enumerated() {
                let fileName = try MistakeAttachmentStore.save(
                    data: attachment.data,
                    preferredExtension: attachment.pathExtension,
                    directory: attachmentDirectory
                )
                savedFileNames.append(fileName)
                context.insert(
                    MistakeAttachment(
                        itemID: target.id,
                        fileName: fileName,
                        originalFileName: attachment.originalFileName,
                        sortIndex: startingIndex + offset,
                        createdAt: now
                    )
                )
            }
            try context.save()
            return target
        } catch {
            context.rollback()
            for fileName in savedFileNames {
                try? MistakeAttachmentStore.remove(
                    fileName: fileName,
                    directory: attachmentDirectory
                )
            }
            throw error
        }
    }

    static func recordReview(
        for item: MistakeLibraryItem,
        outcome: MistakeReviewOutcome,
        drawing: PKDrawing,
        note: String,
        in context: ModelContext,
        now: Date = .now,
        calendar: Calendar = .current
    ) throws {
        let update = MistakeReviewEngine.update(
            after: outcome,
            currentCorrectStreak: item.correctStreak,
            at: now,
            calendar: calendar
        )
        context.insert(
            MistakeReviewAttempt(
                itemID: item.id,
                outcome: outcome,
                drawingData: drawing.dataRepresentation(),
                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: now
            )
        )
        item.status = update.status
        item.correctStreak = update.correctStreak
        item.reviewCount += 1
        item.lastReviewedAt = now
        item.nextReviewAt = update.nextReviewAt
        item.updatedAt = now
        try context.save()
    }

    static func moveToTrash(
        _ item: MistakeLibraryItem,
        in context: ModelContext,
        now: Date = .now
    ) throws {
        item.deletedAt = now
        item.updatedAt = now
        try context.save()
    }

    static func restore(
        _ item: MistakeLibraryItem,
        in context: ModelContext,
        now: Date = .now
    ) throws {
        item.deletedAt = nil
        item.updatedAt = now
        try context.save()
    }

    static func setFavorite(
        _ isFavorite: Bool,
        for item: MistakeLibraryItem,
        in context: ModelContext,
        now: Date = .now
    ) throws {
        item.isFavorite = isFavorite
        item.updatedAt = now
        try context.save()
    }

    static func toggleArchive(
        _ item: MistakeLibraryItem,
        in context: ModelContext,
        now: Date = .now
    ) throws {
        if item.status == .archived {
            item.status = item.statusBeforeArchive ?? .learning
            item.statusBeforeArchive = nil
        } else {
            item.statusBeforeArchive = item.status
            item.status = .archived
        }
        item.updatedAt = now
        try context.save()
    }

    static func permanentlyDelete(
        _ item: MistakeLibraryItem,
        attachments: [MistakeAttachment],
        attempts: [MistakeReviewAttempt],
        in context: ModelContext,
        attachmentDirectory: URL = AppStorageDirectory.mistakeAttachments
    ) throws {
        let fileNames = attachments.map(\.fileName)
        let stagedFiles = try MistakeAttachmentStore.stageForDeletion(
            fileNames: fileNames,
            directory: attachmentDirectory
        )
        do {
            attempts.forEach(context.delete)
            attachments.forEach(context.delete)
            context.delete(item)
            try context.save()
        } catch {
            context.rollback()
            try? stagedFiles.rollback()
            throw error
        }
        // The logical delete is committed. A failed staging-directory cleanup
        // leaves no visible user data and is retried during the next startup.
        try? stagedFiles.commit()
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalizedTags(_ value: String) -> String {
        value
            .replacingOccurrences(of: "，", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ",")
    }
}
