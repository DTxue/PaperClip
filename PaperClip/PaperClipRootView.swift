import SwiftUI

struct AppRootView: View {
    @State private var startupError: AppAlert?
    @AppStorage("appColorScheme") private var appColorScheme = "system"

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

    var body: some View {
        RootView()
            .appAlert($startupError)
            .paperClipColorScheme(preferredColorScheme)
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
