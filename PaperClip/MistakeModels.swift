import Foundation
import SwiftData

extension PaperClipSchemaV1 {
/// Legacy persisted model retained only so existing stores and backups remain readable.
/// The retired mistake-library feature must not add new records through this type.
@Model
final class MistakeCard {
    @Attribute(.unique) var id: UUID
    var imageFileName: String
    var originalWidth: Double
    var originalHeight: Double
    var aspectRatio: Double
    var printWidthMM: Double
    var printHeightMM: Double
    var grade: String
    var semester: String
    var subject: String
    var tagsText: String
    var errorReason: String
    var status: String
    var note: String
    var createdAt: Date
    var updatedAt: Date
    // Legacy recognition field. The retired feature no longer schedules work for it.
    var recognitionStatus: String = "completed"
    var recognizedText: String = ""
    /// Legacy AI recognition metadata.
    var questionType: String = ""
    /// AI 生成或用户修订的标准答案；旧数据保持为空并在交卷时转为人工自评
    var correctAnswer: String = ""
    /// Legacy source-document title.
    var sourceDocumentTitle: String = ""
    /// 题目图片在原始截图中的归一化裁剪区域，格式 "x,y,w,h"（0–1），nil 表示未框选
    var questionCrop: String? = nil

    init(
        id: UUID = UUID(),
        imageFileName: String,
        originalWidth: Double,
        originalHeight: Double,
        printWidthMM: Double = 170,
        grade: String = "七年级",
        semester: String = "上学期",
        subject: String = "数学",
        tagsText: String = "",
        errorReason: String = "粗心",
        status: String = "未掌握",
        note: String = "",
        recognitionStatus: String = "completed",
        recognizedText: String = "",
        questionType: String = "",
        correctAnswer: String = "",
        sourceDocumentTitle: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.imageFileName = imageFileName
        self.originalWidth = originalWidth
        self.originalHeight = originalHeight
        let calculatedAspectRatio = originalHeight == 0 ? 1 : originalWidth / originalHeight
        self.aspectRatio = calculatedAspectRatio
        self.printWidthMM = printWidthMM
        self.printHeightMM = calculatedAspectRatio == 0 ? printWidthMM : printWidthMM / calculatedAspectRatio
        self.grade = grade
        self.semester = semester
        self.subject = subject
        self.tagsText = tagsText
        self.errorReason = errorReason
        self.status = status
        self.note = note
        self.recognitionStatus = recognitionStatus
        self.recognizedText = recognizedText
        self.questionType = questionType
        self.correctAnswer = correctAnswer
        self.sourceDocumentTitle = sourceDocumentTitle
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

}
}

typealias MistakeCard = PaperClipSchemaV1.MistakeCard
