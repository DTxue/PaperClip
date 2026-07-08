import SwiftUI

struct AppRootView: View {
    @Environment(\.colorScheme) private var systemColorScheme

    @State private var startupError: AppAlert?
    @AppStorage("appColorScheme") private var appColorScheme = "system"
    @AppStorage(PaperClipAppTheme.storageKey) private var appThemeRaw = PaperClipAppTheme.defaultValue.rawValue
    @AppStorage(PaperClipReadingTheme.storageKey) private var readingThemeRaw = PaperClipReadingTheme.defaultValue.rawValue

    init(startupError: AppAlert?) {
        _startupError = State(initialValue: startupError)
    }

    private var preferredColorScheme: ColorScheme? {
        switch appColorScheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    private var resolvedColorScheme: ColorScheme? {
        preferredColorScheme ?? appTheme.suggestedColorScheme
    }

    private var readingTheme: PaperClipReadingTheme {
        PaperClipReadingTheme.resolve(readingThemeRaw)
    }

    private var appTheme: PaperClipAppTheme {
        PaperClipAppTheme.resolve(appThemeRaw)
    }

    private var effectiveColorScheme: ColorScheme {
        resolvedColorScheme ?? systemColorScheme
    }

    private var appPalette: PaperClipReadingPalette {
        appTheme.palette(for: effectiveColorScheme)
    }

    var body: some View {
        RootView()
            .appAlert($startupError)
            .environment(\.paperClipAppTheme, appTheme)
            .environment(\.paperClipAppPalette, appPalette)
            .environment(\.paperClipReadingTheme, readingTheme)
            .tint(appPalette.accentColor)
            .background(appPalette.pageBackgroundColor.ignoresSafeArea())
            .toolbarBackground(appPalette.panelBackgroundColor, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .paperClipColorScheme(resolvedColorScheme)
    }
}

private struct PaperClipColorSchemeModifier: ViewModifier {
    let scheme: ColorScheme?

    @ViewBuilder
    func body(content: Content) -> some View {
        Group {
            if let scheme {
                content
                    .preferredColorScheme(scheme)
                    .environment(\.colorScheme, scheme)
            } else {
                content
                    .preferredColorScheme(nil)
            }
        }
    }
}

private extension View {
    func paperClipColorScheme(_ scheme: ColorScheme?) -> some View {
        modifier(PaperClipColorSchemeModifier(scheme: scheme))
    }
}
