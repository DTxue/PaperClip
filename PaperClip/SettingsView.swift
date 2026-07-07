import SwiftUI

struct SettingsView: View {
    @State private var selection: SettingsCategory? = .appearance

    var body: some View {
        PaperClipNavigationSplitView {
            SettingsSidebarView(selection: $selection)
        } detail: {
            switch selection {
            case .appearance: AppearanceSettingsView()
            case .learning:   LearningSettingsView()
            case .fsrs:       FSRSExplanationView()
            case .ai:         AISettingsView()
            case .diary:      DiarySettingsView()
            case .writing:    WritingSettingsView()
            case .about:      AboutSettingsView()
            case nil:         ContentUnavailableView("请选择设置项", systemImage: "gearshape")
            }
        }
    }
}
