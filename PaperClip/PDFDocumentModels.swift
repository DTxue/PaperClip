import Foundation
import SwiftData

extension PaperClipSchemaV1 {
@Model
final class PDFDocumentItem {
    static var deletionPropertiesToFetch: [PartialKeyPath<PDFDocumentItem>] {
        [\.id]
    }

    @Attribute(.unique) var id: UUID
    var title: String
    var localFileName: String
    var importDate: Date
    var lastOpenDate: Date
    // 试卷分类字段；带默认值以支持 SwiftData 轻量迁移（旧数据自动填入默认值）。
    var grade: String = Grade.grade7.rawValue
    var semester: String = Semester.first.rawValue
    var subject: String = Subject.math.rawValue
    /// 源 PDF 内容指纹，用于开发更新或记录重建后恢复考试记录关联。
    var fileFingerprint: String = ""

    init(
        id: UUID = UUID(),
        title: String,
        localFileName: String,
        fileFingerprint: String = "",
        grade: String = Grade.grade7.rawValue,
        semester: String = Semester.first.rawValue,
        subject: String = Subject.math.rawValue,
        importDate: Date = .now,
        lastOpenDate: Date = .now
    ) {
        self.id = id
        self.title = title
        self.localFileName = localFileName
        self.fileFingerprint = fileFingerprint
        self.grade = grade
        self.semester = semester
        self.subject = subject
        self.importDate = importDate
        self.lastOpenDate = lastOpenDate
    }

    var localFileURL: URL {
        StoredFile.importedPDF(fileName: localFileName).url
    }
}
}

typealias PDFDocumentItem = PaperClipSchemaV1.PDFDocumentItem
