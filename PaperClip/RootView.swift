import SwiftUI

enum AppSection: Int {
    case home
    case mistakes
    case writing
    case vocabulary
    case statistics
    case settings
}

struct RootView: View {
    @State private var section: AppSection = .home

    var body: some View {
        TabView(selection: $section) {
            Tab("日记", systemImage: "book.fill", value: .home) {
                HomeView()
            }

            Tab("错题库", systemImage: "rectangle.stack.badge.exclamationmark", value: .mistakes) {
                MistakeLibraryView()
            }

            Tab("写作", systemImage: "pencil.and.outline", value: .writing) {
                NavigationStack {
                    WritingHomeView()
                }
            }

            Tab("ENG", systemImage: "character.book.closed", value: .vocabulary) {
                NavigationStack {
                    VocabularyHomeView()
                }
            }

            Tab("统计", systemImage: "chart.bar", value: .statistics) {
                StatisticsView(isActive: section == .statistics)
            }

            Tab("设置", systemImage: "gearshape", value: .settings) {
                SettingsView()
            }
        }
        .tabViewStyle(.tabBarOnly)
    }
}
