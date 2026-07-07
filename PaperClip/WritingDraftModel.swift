import CoreGraphics
import Foundation
import SwiftData

@Model
final class WritingDraft {
    static var deletionPropertiesToFetch: [PartialKeyPath<WritingDraft>] {
        [\.id]
    }

    @Attribute(.unique) var id: UUID
    var promptID: UUID
    var languageRaw: String
    var paperStyleRaw: String
    var blackPaperMode: Bool
    var paperWidth: Double?
    var paperHeight: Double?
    var rulingSpacing: Double?
    @Attribute(.externalStorage) var drawingData: Data
    var recognizedText: String
    var reviewStatusRaw: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        promptID: UUID,
        language: WritingLanguage,
        paperStyle: WritingPaperStyle = .lined,
        blackPaperMode: Bool = false,
        paperWidth: Double = WritingPaperMetrics.defaultWidth,
        paperHeight: Double = WritingPaperMetrics.defaultHeight,
        rulingSpacing: Double? = nil,
        drawingData: Data = Data(),
        recognizedText: String = "",
        reviewStatus: WritingReviewStatus = .draft,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.promptID = promptID
        self.languageRaw = language.rawValue
        self.paperStyleRaw = paperStyle.rawValue
        self.blackPaperMode = blackPaperMode
        self.paperWidth = paperWidth
        self.paperHeight = paperHeight
        self.rulingSpacing = rulingSpacing ?? WritingPaperMetrics.defaultRulingSpacing(for: paperStyle)
        self.drawingData = drawingData
        self.recognizedText = recognizedText
        self.reviewStatusRaw = reviewStatus.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var language: WritingLanguage {
        get { WritingLanguage(rawValue: languageRaw) ?? .chinese }
        set { languageRaw = newValue.rawValue }
    }

    var paperStyle: WritingPaperStyle {
        get { WritingPaperStyle(rawValue: paperStyleRaw) ?? .lined }
        set { paperStyleRaw = newValue.rawValue }
    }

    var paperSize: CGSize {
        get {
            WritingPaperMetrics.clampedSize(
                width: paperWidth ?? WritingPaperMetrics.defaultWidth,
                height: paperHeight ?? WritingPaperMetrics.defaultHeight
            )
        }
        set {
            let clampedSize = WritingPaperMetrics.clampedSize(
                width: newValue.width,
                height: newValue.height
            )
            paperWidth = clampedSize.width
            paperHeight = clampedSize.height
        }
    }

    var paperRulingSpacing: Double {
        get {
            WritingPaperMetrics.clampedRulingSpacing(
                rulingSpacing ?? WritingPaperMetrics.defaultRulingSpacing(for: paperStyle)
            )
        }
        set {
            rulingSpacing = WritingPaperMetrics.clampedRulingSpacing(newValue)
        }
    }

    var reviewStatus: WritingReviewStatus {
        get { WritingReviewStatus(rawValue: reviewStatusRaw) ?? .draft }
        set { reviewStatusRaw = newValue.rawValue }
    }
}
