import Foundation
import SwiftData

enum MistakeLearningStatus: String, CaseIterable, Identifiable, Codable {
    case inbox
    case learning
    case mastered
    case archived

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inbox: "待整理"
        case .learning: "学习中"
        case .mastered: "已掌握"
        case .archived: "已归档"
        }
    }
}

enum MistakeReviewOutcome: String, CaseIterable, Codable {
    case correct
    case incorrect

    var title: String {
        switch self {
        case .correct: "做对了"
        case .incorrect: "还不会"
        }
    }
}

extension PaperClipSchemaV2 {
    @Model
    final class MistakeAttachment {
        @Attribute(.unique) var id: UUID
        var itemID: UUID
        var fileName: String
        var originalFileName: String
        var sortIndex: Int
        var createdAt: Date

        init(
            id: UUID = UUID(),
            itemID: UUID,
            fileName: String,
            originalFileName: String = "",
            sortIndex: Int = 0,
            createdAt: Date = .now
        ) {
            self.id = id
            self.itemID = itemID
            self.fileName = fileName
            self.originalFileName = originalFileName
            self.sortIndex = sortIndex
            self.createdAt = createdAt
        }
    }

    @Model
    final class MistakeReviewAttempt {
        @Attribute(.unique) var id: UUID
        var itemID: UUID
        var outcomeRaw: String
        @Attribute(.externalStorage) var drawingData: Data
        var note: String
        var createdAt: Date

        init(
            id: UUID = UUID(),
            itemID: UUID,
            outcome: MistakeReviewOutcome,
            drawingData: Data = Data(),
            note: String = "",
            createdAt: Date = .now
        ) {
            self.id = id
            self.itemID = itemID
            self.outcomeRaw = outcome.rawValue
            self.drawingData = drawingData
            self.note = note
            self.createdAt = createdAt
        }

        var outcome: MistakeReviewOutcome {
            MistakeReviewOutcome(rawValue: outcomeRaw) ?? .incorrect
        }
    }
}

extension PaperClipSchemaV3 {
    @Model
    final class MistakeLibraryItem {
        @Attribute(.unique) var id: UUID
        var questionText: String
        // Hidden legacy answer fields stay in the V3–V5 storage shape.
        var correctAnswer: String
        var explanation: String
        var errorReason: String
        var subject: String
        var grade: String = Grade.grade7.rawValue
        var semester: String = Semester.first.rawValue
        var source: String
        var tagsText: String
        var statusRaw: String
        var statusBeforeArchiveRaw: String?
        var isFavorite: Bool
        var correctStreak: Int
        var reviewCount: Int
        var nextReviewAt: Date?
        var lastReviewedAt: Date?
        var deletedAt: Date?
        var createdAt: Date
        var updatedAt: Date

        init(
            id: UUID = UUID(),
            questionText: String = "",
            correctAnswer: String = "",
            explanation: String = "",
            errorReason: String = "",
            subject: String = Subject.math.rawValue,
            grade: String = Grade.grade7.rawValue,
            semester: String = Semester.first.rawValue,
            source: String = "",
            tagsText: String = "",
            status: MistakeLearningStatus = .inbox,
            statusBeforeArchive: MistakeLearningStatus? = nil,
            isFavorite: Bool = false,
            correctStreak: Int = 0,
            reviewCount: Int = 0,
            nextReviewAt: Date? = nil,
            lastReviewedAt: Date? = nil,
            deletedAt: Date? = nil,
            createdAt: Date = .now,
            updatedAt: Date = .now
        ) {
            self.id = id
            self.questionText = questionText
            self.correctAnswer = correctAnswer
            self.explanation = explanation
            self.errorReason = errorReason
            self.subject = subject
            self.grade = grade
            self.semester = semester
            self.source = source
            self.tagsText = tagsText
            self.statusRaw = status.rawValue
            self.statusBeforeArchiveRaw = statusBeforeArchive?.rawValue
            self.isFavorite = isFavorite
            self.correctStreak = correctStreak
            self.reviewCount = reviewCount
            self.nextReviewAt = nextReviewAt
            self.lastReviewedAt = lastReviewedAt
            self.deletedAt = deletedAt
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }

        var status: MistakeLearningStatus {
            get { MistakeLearningStatus(rawValue: statusRaw) ?? .inbox }
            set { statusRaw = newValue.rawValue }
        }

        var statusBeforeArchive: MistakeLearningStatus? {
            get { statusBeforeArchiveRaw.flatMap(MistakeLearningStatus.init(rawValue:)) }
            set { statusBeforeArchiveRaw = newValue?.rawValue }
        }

        var tags: [String] {
            tagsText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
    }
}

typealias MistakeLibraryItem = PaperClipSchemaV3.MistakeLibraryItem
typealias MistakeAttachment = PaperClipSchemaV2.MistakeAttachment
typealias MistakeReviewAttempt = PaperClipSchemaV2.MistakeReviewAttempt
