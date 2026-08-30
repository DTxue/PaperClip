import SwiftUI

struct StatCard<Content: View>: View {
    @Environment(\.paperClipAppPalette) private var palette

    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.secondaryTextColor)
            content
        }
        .padding(12)
        .background(palette.panelBackgroundColor, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8).stroke(palette.borderColor.opacity(0.7))
        }
    }
}

struct StatisticsCardEmptyState: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(description)
        )
        .frame(maxWidth: .infinity, minHeight: 72)
    }
}
