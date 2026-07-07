import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("appColorScheme") private var appColorScheme = "system"

    var body: some View {
        Form {
            Section {
                Picker("主题", selection: $appColorScheme) {
                    Text("跟随系统").tag("system")
                    Text("浅色").tag("light")
                    Text("深色").tag("dark")
                }
                .pickerStyle(.segmented)
            } header: {
                Text("界面主题")
            } footer: {
                Text("选择「跟随系统」时，PaperClip 会随 iPad 系统设置自动切换明暗模式。")
            }
        }
        .navigationTitle("外观")
        .navigationBarTitleDisplayMode(.inline)
    }
}
