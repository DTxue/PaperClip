import Foundation
import SwiftData

extension MistakeCardRowData {
    static var propertiesToFetch: [PartialKeyPath<MistakeCard>] {
        [
            \.id,
            \.imageFileName,
            \.grade,
            \.semester,
            \.subject,
            \.tagsText,
            \.status,
            \.note,
            \.createdAt,
            \.recognitionStatus,
            \.recognizedText,
            \.questionType,
            \.correctAnswer,
            \.sourceDocumentTitle
        ]
    }

    init(card: MistakeCard) {
        self.init(
            id: card.id,
            imageFileName: card.imageFileName,
            grade: card.grade,
            semester: card.semester,
            subject: card.subject,
            tagsText: card.tagsText,
            status: card.status,
            note: card.note,
            createdAt: card.createdAt,
            recognitionStatus: card.recognitionStatus,
            recognizedText: card.recognizedText,
            questionType: card.questionType,
            correctAnswer: card.correctAnswer,
            sourceDocumentTitle: card.sourceDocumentTitle
        )
    }
}
