import Foundation
import SwiftData

struct AppAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String

    init(title: String, message: String) {
        self.title = title
        self.message = message
    }

    init(title: String, error: Error) {
        self.init(title: title, message: error.localizedDescription)
    }
}

@Model
final class PDFDocumentItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var localFileName: String
    var importDate: Date
    var lastOpenDate: Date
    // 试卷分类字段；带默认值以支持 SwiftData 轻量迁移（旧数据自动填入默认值）。
    var grade: String = Grade.grade7.rawValue
    var semester: String = Semester.first.rawValue
    var subject: String = Subject.math.rawValue

    init(
        id: UUID = UUID(),
        title: String,
        localFileName: String,
        grade: String = Grade.grade7.rawValue,
        semester: String = Semester.first.rawValue,
        subject: String = Subject.math.rawValue,
        importDate: Date = .now,
        lastOpenDate: Date = .now
    ) {
        self.id = id
        self.title = title
        self.localFileName = localFileName
        self.grade = grade
        self.semester = semester
        self.subject = subject
        self.importDate = importDate
        self.lastOpenDate = lastOpenDate
    }

    var localFileURL: URL {
        AppStorageDirectory.pdfs.appendingPathComponent(localFileName)
    }
}

@Model
final class HandwritingLayer {
    @Attribute(.unique) var id: UUID
    var documentId: UUID
    var pageIndex: Int
    @Attribute(.externalStorage) var drawingData: Data
    /// 同一次做题会话内所有页面共享同一个 sessionIndex（从 1 开始）。
    /// 旧数据迁移后默认为 1，"新建练习"时递增。
    var sessionIndex: Int = 1
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        documentId: UUID,
        pageIndex: Int,
        drawingData: Data,
        sessionIndex: Int = 1,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.documentId = documentId
        self.pageIndex = pageIndex
        self.drawingData = drawingData
        self.sessionIndex = sessionIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

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
        AppStorageDirectory.cards.appendingPathComponent(imageFileName)
    }

    var tags: [String] {
        tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var resolvedQuestionType: QuestionType {
        QuestionType.resolve(questionType, questionText: recognizedText)
    }
}

@Model
final class ExportRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var cardIDsText: String
    var layoutType: String
    var exportType: String
    var pdfFileName: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        cardIDs: [UUID],
        layoutType: String,
        exportType: String,
        pdfFileName: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.cardIDsText = cardIDs.map(\.uuidString).joined(separator: ",")
        self.layoutType = layoutType
        self.exportType = exportType
        self.pdfFileName = pdfFileName
        self.createdAt = createdAt
    }

    var pdfURL: URL {
        AppStorageDirectory.exports.appendingPathComponent(pdfFileName)
    }
}

enum Grade: String, CaseIterable, Identifiable {
    case grade7 = "七年级"
    case grade8 = "八年级"
    case grade9 = "九年级"
    var id: String { rawValue }
}

enum Semester: String, CaseIterable, Identifiable {
    case first = "上学期"
    case second = "下学期"
    var id: String { rawValue }
}

enum Subject: String, CaseIterable, Identifiable {
    case chinese = "语文"
    case math = "数学"
    case english = "英语"
    case physics = "物理"
    case chemistry = "化学"
    case biology = "生物"
    case history = "历史"
    case geography = "地理"
    case politics = "道德与法治"
    case music = "音乐"
    case art = "美术"
    case pe = "体育"
    case it = "信息技术"
    var id: String { rawValue }
}

enum MasteryStatus: String, CaseIterable, Identifiable {
    case unmastered = "未掌握"
    case review = "待复习"
    case mastered = "已掌握"
    var id: String { rawValue }

    /// 升一级：未掌握 → 待复习 → 已掌握（已掌握不变）。
    static func nextLevel(after status: String) -> MasteryStatus {
        switch status {
        case unmastered.rawValue: return .review
        case review.rawValue: return .mastered
        default: return .mastered
        }
    }
}

enum QuestionType: String, CaseIterable, Identifiable {
    case choice = "选择题"
    case fillBlank = "填空题"
    case trueFalse = "判断题"
    case calculation = "计算题"
    case reading = "阅读理解"
    case shortAnswer = "简答题"
    case proof = "证明题"
    case composition = "作文题"
    case other = "其他"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .choice: "list.bullet.circle"
        case .fillBlank: "rectangle.and.pencil.and.ellipsis"
        case .trueFalse: "checkmark.circle"
        case .calculation: "function"
        case .reading: "text.book.closed"
        case .shortAnswer: "text.alignleft"
        case .proof: "checkmark.seal"
        case .composition: "doc.richtext"
        case .other: "square.grid.2x2"
        }
    }

    static func resolve(_ value: String, questionText: String = "") -> QuestionType {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if let exact = allCases.first(where: { $0.rawValue == trimmed }) {
            return exact
        }
        let normalized = trimmed.lowercased()

        if normalized.contains("选择") || normalized.contains("单选") || normalized.contains("多选") {
            return .choice
        }
        if normalized.contains("填空") {
            return .fillBlank
        }
        if normalized.contains("判断") || normalized.contains("是非") {
            return .trueFalse
        }
        if normalized.contains("计算") || normalized.contains("运算") || normalized.contains("解方程") {
            return .calculation
        }
        if normalized.contains("阅读") || normalized.contains("材料分析") {
            return .reading
        }
        if normalized.contains("简答") || normalized.contains("问答") {
            return .shortAnswer
        }
        if normalized.contains("证明") {
            return .proof
        }
        if normalized.contains("作文") || normalized.contains("写作") {
            return .composition
        }

        let text = questionText.lowercased()
        if hasChoiceMarkers(in: text) { return .choice }
        if text.contains("判断下列") || text.contains("判断正误") || text.contains("正确还是错误") {
            return .trueFalse
        }
        if text.contains("填空") || text.contains("横线上") || text.contains("空格中") {
            return .fillBlank
        }
        if text.contains("阅读材料") || text.contains("阅读下面") || text.contains("阅读短文") {
            return .reading
        }
        if text.contains("计算") || text.contains("求值") || text.contains("解方程") {
            return .calculation
        }
        if text.contains("证明") { return .proof }
        if text.contains("作文") || text.contains("写作") { return .composition }

        return .other
    }

    private static func hasChoiceMarkers(in text: String) -> Bool {
        let pattern = #"(?:^|[\s\n])[（(]?[A-Da-dＡ-Ｄａ-ｄ][）)]?\s*[\.．、:：]"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return expression.numberOfMatches(in: text, range: range) >= 2
    }
}

enum ErrorReason: String, CaseIterable, Identifiable {
    case concept = "概念不清"
    case calculation = "计算错误"
    case reading = "审题错误"
    case careless = "粗心"
    case incomplete = "步骤不完整"
    case formula = "公式记错"
    case method = "方法不会"
    case other = "其他"
    var id: String { rawValue }
}

enum ExportLayout: Int, CaseIterable, Identifiable {
    case one = 1
    case two = 2
    case four = 4
    var id: Int { rawValue }
    var title: String { "每页 \(rawValue) 题" }
}

enum ExportKind: String, CaseIterable, Identifiable {
    case practice = "练习版"
    case review = "复习版"
    var id: String { rawValue }
}

enum RecognitionStatus: String {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
}

/// 一次错题练习会话中，每张错题卡对应一个画布层 + 标记结果。
/// practiceGroupID 将同一批次的多轮练习关联在一起（"再练一轮"时 round 递增）。
@Model
final class MistakePracticeLayer {
    @Attribute(.unique) var id: UUID
    var cardID: UUID
    var practiceGroupID: UUID
    /// 第几轮（从 1 开始），"再练一轮"时递增
    var round: Int
    @Attribute(.externalStorage) var drawingData: Data
    /// "" 未标记 | "got_it" 会了 | "not_yet" 还不会
    var mark: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        cardID: UUID,
        practiceGroupID: UUID,
        round: Int = 1,
        drawingData: Data = Data(),
        mark: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.cardID = cardID
        self.practiceGroupID = practiceGroupID
        self.round = round
        self.drawingData = drawingData
        self.mark = mark
        self.createdAt = createdAt
    }
}

enum PracticeMark: String {
    case gotIt    = "got_it"
    case notYet   = "not_yet"
    case unmarked = ""
}

extension Subject {
    /// 将 AI 返回的学科字符串映射到枚举，支持精确匹配和包含匹配。
    static func from(aiString: String) -> Subject? {
        allCases.first { $0.rawValue == aiString }
            ?? allCases.first { aiString.contains($0.rawValue) }
    }
}
