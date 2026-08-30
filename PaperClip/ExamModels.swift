import Foundation
import SwiftData

extension PaperClipSchemaV1 {
@Model
final class ExamAttempt {
    static var cascadeDeletionPropertiesToFetch: [PartialKeyPath<ExamAttempt>] {
        [\.id, \.generatedPDFFileName]
    }

    @Attribute(.unique) var id: UUID
    var sourceDocumentId: UUID
    var sourceDocumentTitle: String
    /// 源 PDF 文件名和内容指纹是考试记录的稳定身份。即使 PDFDocumentItem.id
    /// 在开发迁移中变化，也可用它们重新绑定记录。
    var sourceDocumentLocalFileName: String = ""
    var sourceDocumentFingerprint: String = ""
    /// 由源 PDF + selectedPageIndicesText 生成的考试 PDF 缓存文件名。
    /// 文件丢失时可重新生成；删除源试卷时统一清理缓存。
    var generatedPDFFileName: String
    /// 原 PDF 页码索引列表，使用英文逗号分隔，按考试页序保存。
    var selectedPageIndicesText: String
    var status: String
    var createdAt: Date
    var submittedAt: Date?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        sourceDocumentId: UUID,
        sourceDocumentTitle: String,
        sourceDocumentLocalFileName: String = "",
        sourceDocumentFingerprint: String = "",
        generatedPDFFileName: String,
        selectedPageIndices: [Int],
        status: String = ExamAttemptStatus.inProgress.rawValue,
        createdAt: Date = .now,
        submittedAt: Date? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.sourceDocumentId = sourceDocumentId
        self.sourceDocumentTitle = sourceDocumentTitle
        self.sourceDocumentLocalFileName = sourceDocumentLocalFileName
        self.sourceDocumentFingerprint = sourceDocumentFingerprint
        self.generatedPDFFileName = generatedPDFFileName
        self.selectedPageIndicesText = PDFPageIndexDisplay.serializeStoredIndices(selectedPageIndices)
        self.status = status
        self.createdAt = createdAt
        self.submittedAt = submittedAt
        self.updatedAt = updatedAt
    }

    var selectedPageIndices: [Int] {
        PDFPageIndexDisplay.parseStoredIndices(selectedPageIndicesText)
    }

    var generatedPDFURL: URL {
        StoredFile.examPDF(fileName: generatedPDFFileName).url
    }
}
}

typealias ExamAttempt = PaperClipSchemaV1.ExamAttempt

struct ExamAttemptQuestionMetrics: Equatable, Hashable {
    var correctCount: Int = 0
    var incorrectCount: Int = 0

    var totalCount: Int { correctCount + incorrectCount }

    mutating func add(isCorrect: Bool) {
        if isCorrect {
            correctCount += 1
        } else {
            incorrectCount += 1
        }
    }

    mutating func add(_ other: ExamAttemptQuestionMetrics) {
        correctCount += other.correctCount
        incorrectCount += other.incorrectCount
    }
}
