import Foundation
import SwiftData

@Model
final class MistakeCard {
    static var unfinishedRecognitionPropertiesToFetch: [PartialKeyPath<MistakeCard>] {
        [\.id, \.imageFileName, \.recognitionStatus]
    }

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
    // AI 后台识别字段：默认 completed 保证旧数据不被重新识别
    var recognitionStatus: String = RecognitionStatus.completed.rawValue
    var recognizedText: String = ""
    /// AI 识别的题型，例如“选择题”；旧数据默认为空并由题目文本回退判断
    var questionType: String = ""
    /// AI 生成或用户修订的标准答案；旧数据保持为空并在交卷时转为人工自评
    var correctAnswer: String = ""
    /// 错题卡所在试卷的标题（创建时写入，之后只读）
    var sourceDocumentTitle: String = ""
    /// 题目图片在原始截图中的归一化裁剪区域，格式 "x,y,w,h"（0–1），nil 表示未框选
    var questionCrop: String? = nil

    init(
        id: UUID = UUID(),
        imageFileName: String,
        originalWidth: Double,
        originalHeight: Double,
        printWidthMM: Double = 170,
        grade: String = Grade.grade7.rawValue,
        semester: String = Semester.first.rawValue,
        subject: String = Subject.math.rawValue,
        tagsText: String = "",
        errorReason: String = ErrorReason.careless.rawValue,
        status: String = MasteryStatus.unmastered.rawValue,
        note: String = "",
        recognitionStatus: String = RecognitionStatus.completed.rawValue,
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

    var imageURL: URL {
        StoredFile.cardImage(fileName: imageFileName).url
    }

    var tags: [String] {
        MistakeTagParser.parse(tagsText)
    }

    var tagPreviewText: String {
        MistakeTagDisplay.preview(tags, limit: 2)
    }

    var resolvedQuestionType: QuestionType {
        QuestionType.resolve(questionType, questionText: recognizedText)
    }
}
