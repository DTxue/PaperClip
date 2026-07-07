import Foundation

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

extension Subject {
    /// 将 AI 返回的学科字符串映射到枚举，支持精确匹配和包含匹配。
    static func from(aiString: String) -> Subject? {
        allCases.first { $0.rawValue == aiString }
            ?? allCases.first { aiString.contains($0.rawValue) }
    }

    var sfSymbol: String {
        switch self {
        case .math:
            return "function"
        case .chinese:
            return "character.book.closed"
        case .english:
            return "globe"
        case .physics:
            return "atom"
        case .chemistry:
            return "flask"
        case .biology:
            return "leaf"
        case .history:
            return "building.columns"
        case .geography:
            return "map"
        case .politics:
            return "scale.3d"
        case .music:
            return "music.note"
        case .art:
            return "paintpalette"
        case .pe:
            return "figure.run"
        case .it:
            return "laptopcomputer"
        }
    }
}
