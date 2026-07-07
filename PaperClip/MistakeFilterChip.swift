import SwiftUI

struct MistakeFilterChip<Content: View>: View {
    let isActive: Bool
    let activeForeground: Color
    let inactiveForeground: Color
    let activeBackground: Color
    let inactiveBackground: Color
    let activeStroke: Color
    let horizontalPadding: CGFloat
    let accessibilityLabel: String
    let action: () -> Void
    let content: Content

    init(
        isActive: Bool,
        activeForeground: Color,
        inactiveForeground: Color = .primary,
        activeBackground: Color,
        inactiveBackground: Color = Color.secondary.opacity(0.09),
        activeStroke: Color = .clear,
        horizontalPadding: CGFloat = 12,
        accessibilityLabel: String,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.isActive = isActive
        self.activeForeground = activeForeground
        self.inactiveForeground = inactiveForeground
        self.activeBackground = activeBackground
        self.inactiveBackground = inactiveBackground
        self.activeStroke = activeStroke
        self.horizontalPadding = horizontalPadding
        self.accessibilityLabel = accessibilityLabel
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            content
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isActive ? activeForeground : inactiveForeground)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 7)
                .background(
                    isActive ? activeBackground : inactiveBackground,
                    in: Capsule()
                )
                .overlay {
                    Capsule().stroke(isActive ? activeStroke : .clear, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
