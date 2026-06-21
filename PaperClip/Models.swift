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

    init(
        id: UUID = UUID(),
        title: String,
        localFileName: String,
        importDate: Date = .now,
        lastOpenDate: Date = .now
    ) {
        self.id = id
        self.title = title
        self.localFileName = localFileName
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
    /// 错题卡所在试卷的标题（创建时写入，之后只读）
    var sourceDocumentTitle: String = ""

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
