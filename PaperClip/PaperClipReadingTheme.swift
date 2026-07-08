import SwiftUI
import UIKit

enum PaperClipAppTheme: String, CaseIterable, Identifiable {
    static let storageKey = "paperClipAppTheme"
    static let defaultValue = PaperClipAppTheme.system

    case system
    case paper
    case warmGray
    case lowLight
    case amber

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "默认"
        case .paper: "柔和纸白"
        case .warmGray: "暖灰"
        case .lowLight: "墨绿低光"
        case .amber: "琥珀夜读"
        }
    }

    var description: String {
        switch self {
        case .system:
            "保持系统原生界面色彩。"
        case .paper:
            "降低纯白亮度，用暖白和深灰提升长时间阅读舒适度。"
        case .warmGray:
            "用中性暖灰降低背景眩光，适合作为日常护眼主题。"
        case .lowLight:
            "深灰绿背景配柔和浅色文字，适合暗光环境。"
        case .amber:
            "深暖色背景配米色文字，适合夜间低亮度使用。"
        }
    }

    var suggestedColorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .paper, .warmGray:
            .light
        case .lowLight, .amber:
            .dark
        }
    }

    func palette(for colorScheme: ColorScheme) -> PaperClipReadingPalette {
        switch self {
        case .system:
            colorScheme == .dark ? .systemDark : .systemLight
        case .paper:
            .paper
        case .warmGray:
            .warmGray
        case .lowLight:
            .lowLight
        case .amber:
            .amber
        }
    }

    static func resolve(_ rawValue: String) -> PaperClipAppTheme {
        PaperClipAppTheme(rawValue: rawValue) ?? defaultValue
    }
}

enum PaperClipReadingTheme: String, CaseIterable, Identifiable {
    static let storageKey = "paperClipReadingTheme"
    static let defaultValue = PaperClipReadingTheme.warmGray

    case system
    case paper
    case warmGray
    case lowLight
    case amber

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "跟随界面"
        case .paper: "柔和纸白"
        case .warmGray: "暖灰阅读"
        case .lowLight: "墨绿低光"
        case .amber: "琥珀夜读"
        }
    }

    var description: String {
        switch self {
        case .system:
            "使用系统浅色或深色的阅读配色。"
        case .paper:
            "暖白背景和深灰文字，适合白天阅读。"
        case .warmGray:
            "降低背景亮度和文字冲击，适合长时间阅读。"
        case .lowLight:
            "深灰绿背景和柔和浅色文字，适合暗光环境。"
        case .amber:
            "深暖色背景和米色文字，适合夜间低亮度阅读。"
        }
    }

    func palette(for colorScheme: ColorScheme) -> PaperClipReadingPalette {
        palette(for: colorScheme, appTheme: .system)
    }

    func palette(for colorScheme: ColorScheme, appTheme: PaperClipAppTheme) -> PaperClipReadingPalette {
        switch self {
        case .system:
            appTheme.palette(for: colorScheme)
        case .paper:
            .paper
        case .warmGray:
            .warmGray
        case .lowLight:
            .lowLight
        case .amber:
            .amber
        }
    }

    static func resolve(_ rawValue: String) -> PaperClipReadingTheme {
        PaperClipReadingTheme(rawValue: rawValue) ?? defaultValue
    }
}

struct PaperClipReadingPalette {
    let pageBackground: UIColor
    let panelBackground: UIColor
    let rowBackground: UIColor
    let chipBackground: UIColor
    let primaryText: UIColor
    let secondaryText: UIColor
    let tertiaryText: UIColor
    let border: UIColor
    let maskOverlay: UIColor
    let accent: UIColor
    let warningBackground: UIColor

    var pageBackgroundColor: Color { Color(uiColor: pageBackground) }
    var panelBackgroundColor: Color { Color(uiColor: panelBackground) }
    var rowBackgroundColor: Color { Color(uiColor: rowBackground) }
    var chipBackgroundColor: Color { Color(uiColor: chipBackground) }
    var primaryTextColor: Color { Color(uiColor: primaryText) }
    var secondaryTextColor: Color { Color(uiColor: secondaryText) }
    var tertiaryTextColor: Color { Color(uiColor: tertiaryText) }
    var borderColor: Color { Color(uiColor: border) }
    var maskOverlayColor: Color { Color(uiColor: maskOverlay) }
    var accentColor: Color { Color(uiColor: accent) }
    var warningBackgroundColor: Color { Color(uiColor: warningBackground) }

    static let systemLight = PaperClipReadingPalette(
        pageBackground: .systemGroupedBackground,
        panelBackground: .secondarySystemGroupedBackground,
        rowBackground: .tertiarySystemGroupedBackground,
        chipBackground: .tertiarySystemGroupedBackground,
        primaryText: .label,
        secondaryText: .secondaryLabel,
        tertiaryText: .tertiaryLabel,
        border: .separator,
        maskOverlay: .secondarySystemGroupedBackground,
        accent: .systemBlue,
        warningBackground: UIColor.systemOrange.withAlphaComponent(0.10)
    )

    static let systemDark = PaperClipReadingPalette(
        pageBackground: .systemGroupedBackground,
        panelBackground: .secondarySystemGroupedBackground,
        rowBackground: .tertiarySystemGroupedBackground,
        chipBackground: .tertiarySystemGroupedBackground,
        primaryText: .label,
        secondaryText: .secondaryLabel,
        tertiaryText: .tertiaryLabel,
        border: .separator,
        maskOverlay: .secondarySystemGroupedBackground,
        accent: .systemBlue,
        warningBackground: UIColor.systemOrange.withAlphaComponent(0.16)
    )

    static let paper = PaperClipReadingPalette(
        pageBackground: UIColor(hex: 0xF7F4EE),
        panelBackground: UIColor(hex: 0xFFFCF6),
        rowBackground: UIColor(hex: 0xF2EDE3),
        chipBackground: UIColor(hex: 0xEFE9DE),
        primaryText: UIColor(hex: 0x26231E),
        secondaryText: UIColor(hex: 0x625D52),
        tertiaryText: UIColor(hex: 0x8A8172),
        border: UIColor(hex: 0xDED4C3),
        maskOverlay: UIColor(hex: 0xF5EFE4),
        accent: UIColor(hex: 0x3F6F8F),
        warningBackground: UIColor(hex: 0xF4D6AA)
    )

    static let warmGray = PaperClipReadingPalette(
        pageBackground: UIColor(hex: 0xECEAE4),
        panelBackground: UIColor(hex: 0xF6F4EE),
        rowBackground: UIColor(hex: 0xE5E1D8),
        chipBackground: UIColor(hex: 0xE1DDD4),
        primaryText: UIColor(hex: 0x242522),
        secondaryText: UIColor(hex: 0x5F615B),
        tertiaryText: UIColor(hex: 0x85877E),
        border: UIColor(hex: 0xD0CBC0),
        maskOverlay: UIColor(hex: 0xE9E5DC),
        accent: UIColor(hex: 0x426C72),
        warningBackground: UIColor(hex: 0xEBD2AA)
    )

    static let lowLight = PaperClipReadingPalette(
        pageBackground: UIColor(hex: 0x111816),
        panelBackground: UIColor(hex: 0x19231F),
        rowBackground: UIColor(hex: 0x22302A),
        chipBackground: UIColor(hex: 0x273731),
        primaryText: UIColor(hex: 0xDDE5DA),
        secondaryText: UIColor(hex: 0xAEB9AA),
        tertiaryText: UIColor(hex: 0x7F8B80),
        border: UIColor(hex: 0x34483F),
        maskOverlay: UIColor(hex: 0x1F2C27),
        accent: UIColor(hex: 0x8AB4A2),
        warningBackground: UIColor(hex: 0x4B3923)
    )

    static let amber = PaperClipReadingPalette(
        pageBackground: UIColor(hex: 0x1C1712),
        panelBackground: UIColor(hex: 0x282118),
        rowBackground: UIColor(hex: 0x342A1E),
        chipBackground: UIColor(hex: 0x3A2F22),
        primaryText: UIColor(hex: 0xE8D7B9),
        secondaryText: UIColor(hex: 0xC3AF8F),
        tertiaryText: UIColor(hex: 0x947F60),
        border: UIColor(hex: 0x4D3D2B),
        maskOverlay: UIColor(hex: 0x30261B),
        accent: UIColor(hex: 0xD2A65F),
        warningBackground: UIColor(hex: 0x4D341D)
    )
}

private extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

private struct PaperClipReadingThemeKey: EnvironmentKey {
    static let defaultValue = PaperClipReadingTheme.defaultValue
}

private struct PaperClipAppThemeKey: EnvironmentKey {
    static let defaultValue = PaperClipAppTheme.defaultValue
}

private struct PaperClipAppPaletteKey: EnvironmentKey {
    static let defaultValue = PaperClipAppTheme.defaultValue.palette(for: .light)
}

extension EnvironmentValues {
    var paperClipReadingTheme: PaperClipReadingTheme {
        get { self[PaperClipReadingThemeKey.self] }
        set { self[PaperClipReadingThemeKey.self] = newValue }
    }

    var paperClipAppTheme: PaperClipAppTheme {
        get { self[PaperClipAppThemeKey.self] }
        set { self[PaperClipAppThemeKey.self] = newValue }
    }

    var paperClipAppPalette: PaperClipReadingPalette {
        get { self[PaperClipAppPaletteKey.self] }
        set { self[PaperClipAppPaletteKey.self] = newValue }
    }
}

enum PaperClipThemeSurfaceStyle {
    case page
    case sidebar

    func backgroundColor(from palette: PaperClipReadingPalette) -> Color {
        switch self {
        case .page:
            palette.pageBackgroundColor
        case .sidebar:
            palette.panelBackgroundColor
        }
    }
}

private struct PaperClipThemeSurfaceModifier: ViewModifier {
    @Environment(\.paperClipAppPalette) private var palette

    let style: PaperClipThemeSurfaceStyle

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .foregroundStyle(palette.primaryTextColor)
            .background(style.backgroundColor(from: palette).ignoresSafeArea())
            .tint(palette.accentColor)
    }
}

extension View {
    func paperClipThemedSurface(_ style: PaperClipThemeSurfaceStyle = .page) -> some View {
        modifier(PaperClipThemeSurfaceModifier(style: style))
    }
}
