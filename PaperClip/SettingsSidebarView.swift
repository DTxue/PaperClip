import SwiftUI

enum SettingsCategory: String, CaseIterable, Identifiable {
    case appearance = "外观"
    case learning = "学习"
    case fsrs = "FSRS-6"
    case ai = "AI 功能"
    case diary = "日记"
    case writing = "写作"
    case about = "关于"

    var id: Self { self }

    var icon: String {
        switch self {
        case .appearance: return "circle.lefthalf.filled"
        case .learning: return "graduationcap"
        case .fsrs: return "brain.head.profile"
        case .ai: return "brain"
        case .diary: return "book.pages"
        case .writing: return "pencil.and.outline"
        case .about: return "info.circle"
        }
    }
}

struct SettingsSidebarView: View {
    @Binding var selection: SettingsCategory?

    var body: some View {
        List(SettingsCategory.allCases, selection: $selection) { category in
            Label(category.rawValue, systemImage: category.icon)
                .tag(category)
        }
        .paperClipSidebarColumn("设置")
    }
}
