import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("appColorScheme") private var appColorScheme = "system"
    @AppStorage(PaperClipReadingTheme.storageKey) private var readingThemeRaw = PaperClipReadingTheme.defaultValue.rawValue

    private var selectedReadingTheme: PaperClipReadingTheme {
        PaperClipReadingTheme.resolve(readingThemeRaw)
    }

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

            Section {
                Picker("阅读主题", selection: $readingThemeRaw) {
                    ForEach(PaperClipReadingTheme.allCases) { theme in
                        Text(theme.title).tag(theme.rawValue)
                    }
                }

                ReadingThemePreview(theme: selectedReadingTheme)
            } header: {
                Text("阅读护眼主题")
            } footer: {
                Text(selectedReadingTheme.description)
            }
        }
        .navigationTitle("外观")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ReadingThemePreview: View {
    @Environment(\.colorScheme) private var colorScheme

    let theme: PaperClipReadingTheme

    private var palette: PaperClipReadingPalette {
        theme.palette(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(PaperClipReadingTheme.allCases) { theme in
                let previewPalette = theme.palette(for: colorScheme)
                RoundedRectangle(cornerRadius: 8)
                    .fill(previewPalette.panelBackgroundColor)
                    .frame(width: 48, height: 36)
                    .overlay(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 4) {
                            Capsule()
                                .fill(previewPalette.primaryTextColor)
                                .frame(width: 24, height: 3)
                            Capsule()
                                .fill(previewPalette.secondaryTextColor)
                                .frame(width: 32, height: 3)
                            Capsule()
                                .fill(previewPalette.tertiaryTextColor)
                                .frame(width: 18, height: 3)
                        }
                        .padding(.leading, 8)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                self.theme == theme ? palette.accentColor : previewPalette.borderColor,
                                lineWidth: self.theme == theme ? 2 : 1
                            )
                    }
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
