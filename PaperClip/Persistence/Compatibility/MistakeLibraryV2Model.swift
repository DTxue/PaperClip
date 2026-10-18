import Foundation
import SwiftData

// Historical item shape used only by the V2 migration stage.
extension PaperClipSchemaV2 {
    @Model
    final class MistakeLibraryItem {
        @Attribute(.unique) var id: UUID
        var questionText: String
        var correctAnswer: String
        var explanation: String
        var errorReason: String
        var subject: String
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
