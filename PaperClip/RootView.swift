import SwiftUI

enum AppSection: Int {
    case home
    case library
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

            Tab("题库", systemImage: "books.vertical", value: .library) {
                NavigationStack {
                    SubjectLibraryView()
                }
            }

            Tab("写作", systemImage: "pencil.and.outline", value: .writing) {
                NavigationStack {
                    WritingHomeView()
                }
            }

            Tab("刷子", systemImage: "character.book.closed", value: .vocabulary) {
                NavigationStack {
                    VocabularyHomeView()
                }
            }

            Tab("统计", systemImage: "chart.bar", value: .statistics) {
                NavigationStack {
                    StatisticsView()
                }
            }

            Tab("设置", systemImage: "gearshape", value: .settings) {
                SettingsView()
            }
        }
        .tabViewStyle(.tabBarOnly)
    }
}
