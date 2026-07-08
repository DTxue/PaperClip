import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("appColorScheme") private var appColorScheme = "system"
    @AppStorage(PaperClipAppTheme.storageKey) private var appThemeRaw = PaperClipAppTheme.defaultValue.rawValue
    @AppStorage(PaperClipReadingTheme.storageKey) private var readingThemeRaw = PaperClipReadingTheme.defaultValue.rawValue

    private var selectedAppTheme: PaperClipAppTheme {
        PaperClipAppTheme.resolve(appThemeRaw)
    }

    private var selectedReadingTheme: PaperClipReadingTheme {
        PaperClipReadingTheme.resolve(readingThemeRaw)
    }

    private var appPalette: PaperClipReadingPalette {
        selectedAppTheme.palette(for: colorScheme)
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
                Text("选择「跟随系统」时，默认主题会跟随 iPad 系统；护眼主题会自动使用更适合该配色的浅色或深色界面。")
            }

            Section {
                Picker("舒适主题", selection: $appThemeRaw) {
                    ForEach(PaperClipAppTheme.allCases) { theme in
                        Text(theme.title).tag(theme.rawValue)
                    }
                }

                ThemePreview(
                    selectedAppTheme: selectedAppTheme,
                    selectedReadingTheme: nil
                )
            } header: {
                Text("界面舒适主题")
            } footer: {
                Text(selectedAppTheme.description)
            }

            Section {
                Picker("阅读主题", selection: $readingThemeRaw) {
                    ForEach(PaperClipReadingTheme.allCases) { theme in
                        Text(theme.title).tag(theme.rawValue)
                    }
                }

                ThemePreview(
                    selectedAppTheme: selectedAppTheme,
                    selectedReadingTheme: selectedReadingTheme
                )
            } header: {
                Text("阅读护眼主题")
            } footer: {
                Text(selectedReadingTheme.description)
            }
        }
        .paperClipThemedSurface(.page)
        .tint(appPalette.accentColor)
        .navigationTitle("外观")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ThemePreview: View {
    @Environment(\.colorScheme) private var colorScheme

    let selectedAppTheme: PaperClipAppTheme
    let selectedReadingTheme: PaperClipReadingTheme?

    private var selectedPalette: PaperClipReadingPalette {
        if let selectedReadingTheme {
            selectedReadingTheme.palette(for: colorScheme, appTheme: selectedAppTheme)
        } else {
            selectedAppTheme.palette(for: colorScheme)
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            if let selectedReadingTheme {
                ForEach(PaperClipReadingTheme.allCases) { theme in
                    ThemeSwatch(
                        palette: theme.palette(for: colorScheme, appTheme: selectedAppTheme),
                        isSelected: selectedReadingTheme == theme,
                        selectionColor: selectedPalette.accentColor
                    )
                }
            } else {
                ForEach(PaperClipAppTheme.allCases) { theme in
                    ThemeSwatch(
                        palette: theme.palette(for: colorScheme),
                        isSelected: selectedAppTheme == theme,
                        selectionColor: selectedPalette.accentColor
                    )
                }
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ThemeSwatch: View {
    let palette: PaperClipReadingPalette
    let isSelected: Bool
    let selectionColor: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(palette.panelBackgroundColor)
            .frame(width: 48, height: 36)
            .overlay(alignment: .leading) {
                VStack(alignment: .leading, spacing: 4) {
                    Capsule()
                        .fill(palette.primaryTextColor)
                        .frame(width: 24, height: 3)
                    Capsule()
                        .fill(palette.secondaryTextColor)
                        .frame(width: 32, height: 3)
                    Capsule()
                        .fill(palette.tertiaryTextColor)
                        .frame(width: 18, height: 3)
                }
                .padding(.leading, 8)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? selectionColor : palette.borderColor,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
    }
}
