import Foundation

enum MistakeLibraryFilter: String, CaseIterable, Identifiable {
    case all
    case due
    case favorites
    case inbox
    case learning
    case mastered
    case archived
    case trash

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "全部错题"
        case .due: "待重做"
        case .favorites: "收藏"
        case .inbox: "待整理"
        case .learning: "学习中"
        case .mastered: "已掌握"
        case .archived: "已归档"
        case .trash: "最近删除"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "square.stack"
        case .due: "clock.badge.exclamationmark"
        case .favorites: "star"
        case .inbox: "tray"
        case .learning: "arrow.trianglehead.2.clockwise.rotate.90"
        case .mastered: "checkmark.seal"
        case .archived: "archivebox"
        case .trash: "trash"
        }
    }

    var usesSubjectFolders: Bool { self != .trash }
}

struct MistakeSubjectFolderSummary: Identifiable, Equatable {
    let subject: String
    let count: Int

    var id: String { subject }
}

enum MistakeLibraryOrganizer {
    static func items(
        _ items: [MistakeLibraryItem],
        matching filter: MistakeLibraryFilter,
        now: Date = .now
    ) -> [MistakeLibraryItem] {
        items.filter { matches($0, filter: filter, now: now) }
    }

    static func folders(
        for items: [MistakeLibraryItem],
        matching filter: MistakeLibraryFilter,
        now: Date = .now
    ) -> [MistakeSubjectFolderSummary] {
        let filtered = self.items(items, matching: filter, now: now)
        let knownSubjects = Subject.allCases.map(\.rawValue)
        let unknownSubjects = Set(filtered.map(\.subject))
            .subtracting(knownSubjects)
            .sorted()
        return (knownSubjects + unknownSubjects).map { subject in
            MistakeSubjectFolderSummary(
                subject: subject,
                count: filtered.lazy.filter { $0.subject == subject }.count
            )
        }
    }

    static func matches(
        _ item: MistakeLibraryItem,
        filter: MistakeLibraryFilter,
        now: Date = .now
    ) -> Bool {
        switch filter {
        case .all:
            return item.deletedAt == nil && item.status != .archived
        case .due:
            return item.deletedAt == nil
                && item.status == .learning
                && (item.nextReviewAt ?? .distantPast) <= now
        case .favorites:
            return item.deletedAt == nil && item.status != .archived && item.isFavorite
        case .inbox:
            return item.deletedAt == nil && item.status == .inbox
        case .learning:
            return item.deletedAt == nil && item.status == .learning
        case .mastered:
            return item.deletedAt == nil && item.status == .mastered
        case .archived:
            return item.deletedAt == nil && item.status == .archived
        case .trash:
            return item.deletedAt != nil
        }
    }
}

enum MistakeErrorReasonTag: String, CaseIterable, Identifiable {
    case careless = "粗心"
    case misunderstood = "审题错误"
    case concept = "概念不清"
    case calculation = "计算错误"
    case method = "方法不会"
    case omitted = "步骤遗漏"

    var id: String { rawValue }
}

enum MistakeErrorReasonDraft {
    static func parse(_ storedValue: String) -> (selected: Set<String>, custom: String) {
        let values = components(in: storedValue)
        let known = Set(MistakeErrorReasonTag.allCases.map(\.rawValue))
        return (
            Set(values.filter(known.contains)),
            values.filter { !known.contains($0) }.joined(separator: "，")
        )
    }

    static func storedValue(selected: Set<String>, custom: String) -> String {
        var values = MistakeErrorReasonTag.allCases
            .map(\.rawValue)
            .filter(selected.contains)
        values.append(contentsOf: components(in: custom))
        return Array(NSOrderedSet(array: values))
            .compactMap { $0 as? String }
            .joined(separator: ",")
    }

    private static func components(in value: String) -> [String] {
        value
            .replacingOccurrences(of: "，", with: ",")
            .replacingOccurrences(of: "、", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
