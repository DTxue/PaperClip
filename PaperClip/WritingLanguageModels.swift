import Foundation

enum WritingLanguage: String, Identifiable, Codable {
    case chinese
    case english

    /// 当前产品只开放中文写作；保留 `.english` 以兼容既有持久化数据。
    static let availableCases: [WritingLanguage] = [.chinese]

    var id: Self { self }

    var title: String {
        switch self {
        case .chinese: "中文写作"
        case .english: "英文写作"
        }
    }

    var shortTitle: String {
        switch self {
        case .chinese: "中文"
        case .english: "英文"
        }
    }

    var systemImage: String {
        switch self {
        case .chinese: "character.book.closed"
        case .english: "textformat.abc"
        }
    }

    var defaultFullScore: Int {
        switch self {
        case .chinese: 60
        case .english: 25
        }
    }
}

enum WritingGradeOptions {
    static let all = [
        "小学高年级",
        "初一",
        "初二",
        "初三",
        "高一",
        "高二",
        "高三"
    ]
}
