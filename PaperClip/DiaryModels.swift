import Foundation
import SwiftData

extension PaperClipSchemaV1 {
@Model
final class DiaryEntry {
    var id: UUID
    var date: Date
    var learned: String
    var confused: String
    var noted: String
    var inspired: String
    var aiLearned: String
    var aiConfused: String
    var aiInspired: String
    var aiState: String   // "pending" | "done"
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \KnowledgeItem.diaryEntry)
    var items: [KnowledgeItem] = []

    init(date: Date) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.learned = ""
        self.confused = ""
        self.noted = ""
        self.inspired = ""
        self.aiLearned = ""
        self.aiConfused = ""
        self.aiInspired = ""
        self.aiState = "pending"
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var hasAnyContent: Bool {
        contentPresence.hasAnyContent
    }

    var hasAIProcessableContent: Bool {
        contentPresence.hasAIProcessableContent
    }

    var contentPresence: DiaryEntryContentPresence {
        DiaryEntryContentPresence(
            learned: learned,
            confused: confused,
            noted: noted,
            inspired: inspired
        )
    }
}

@Model
final class KnowledgeItem {
    var id: UUID
    var summary: String
    var source: String         // "learned" | "confused"
    var subject: String
    var status: String         // "draft" | "confirmed"
    var diaryDate: Date
    var aiEssence: String = ""        // 理解层：本质理解
    var aiFormula: String = ""        // 理解层：公式/规律
    var aiExamPattern: String = ""    // 应试层：命题规律
    var aiSolutionPath: String = ""   // 应试层：解题路径
    var aiTrap: String = ""           // 应试层：易错陷阱
    var aiRelated: String = ""        // 深化层：关联考点
    var aiMemoryAnchor: String = ""   // 深化层：记忆锚点
    var aiAnalysisState: String  // "none" | "done" | "failed"
    var changeNote: String = ""  // AI 整理时的改动说明，无改动则为空
    var createdAt: Date
    var updatedAt: Date
    var diaryEntry: DiaryEntry?

    var hasAnalysis: Bool { aiAnalysisState == "done" }

    init(summary: String, source: String, entry: DiaryEntry) {
        self.id = UUID()
        self.summary = summary
        self.source = source
        self.subject = ""
        self.status = "draft"
        self.diaryDate = entry.date
        self.aiAnalysisState = "none"
        self.createdAt = Date()
        self.updatedAt = Date()
        self.diaryEntry = entry
    }
}
}

typealias DiaryEntry = PaperClipSchemaV1.DiaryEntry
typealias KnowledgeItem = PaperClipSchemaV1.KnowledgeItem
